import { afterEach, beforeEach, expect, mock, test } from "bun:test";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

const records = new Map();
const calls = [];
mock.module("herdr", () => ({
  async exec(cmd, args, options) {
    calls.push({ cmd, args, options });
    return execute(cmd, args, options.cwd);
  },
  shared: key => records.get(key),
  setShared: (key, value) => records.set(key, value),
}));
const { lastCommit, takeAmend, writeCommit } = await import("./commits.js");

async function execute(cmd, args, cwd) {
  const process = Bun.spawn([cmd, ...args], { cwd, stdout: "pipe", stderr: "pipe" });
  const [stdout, stderr, code] = await Promise.all([
    new Response(process.stdout).text(), new Response(process.stderr).text(), process.exited,
  ]);
  return { stdout, stderr, code };
}
let root, where;
async function git(...args) {
  const result = await execute("git", args, root);
  if (result.code) throw new Error(result.stderr);
  return result.stdout.trimEnd();
}

beforeEach(async () => {
  root = await mkdtemp(join(tmpdir(), "herdr-commit-"));
  where = { root, on: null };
  await git("init", "-b", "main");
  await git("config", "user.name", "Test");
  await git("config", "user.email", "test@example.com");
  await git("config", "commit.gpgsign", "false");
  await writeFile(join(root, "tracked"), "original\n");
  await git("add", "tracked");
  await git("commit", "-m", "Original subject\n\nOriginal body");
  records.clear(); calls.length = 0;
});
afterEach(async () => { await rm(root, { recursive: true, force: true }); });

test("amend prefills the full message and changes it without adding a commit", async () => {
  const previous = await lastCommit(where);
  expect(previous.message).toBe("Original subject\n\nOriginal body");
  await writeCommit(where, "Updated subject\n\nUpdated body", "amend", previous.head);
  expect(await git("rev-list", "--count", "HEAD")).toBe("1");
  expect(await git("log", "-1", "--format=%B")).toBe("Updated subject\n\nUpdated body");
});

test("amend includes staged changes and preserves unstaged and untracked files", async () => {
  const previous = await lastCommit(where);
  await writeFile(join(root, "tracked"), "staged\n");
  await git("add", "tracked");
  await writeFile(join(root, "tracked"), "unstaged\n");
  await writeFile(join(root, "untracked"), "untracked\n");
  await writeCommit(where, previous.message, "amend", previous.head);
  expect(await git("show", "HEAD:tracked")).toBe("staged");
  expect(await git("status", "--porcelain")).toBe(" M tracked\n?? untracked");
});

test("staged never falls back to all when the index is empty", async () => {
  await writeFile(join(root, "tracked"), "unstaged\n");
  await expect(writeCommit(where, "Staged only", "staged")).rejects.toThrow();
  expect(await git("rev-list", "--count", "HEAD")).toBe("1");
  await git("add", "tracked");
  await writeFile(join(root, "untracked"), "new\n");
  await writeCommit(where, "Staged only", "staged");
  expect(await git("status", "--porcelain")).toBe("?? untracked");
});

test("all includes tracked and untracked changes", async () => {
  await writeFile(join(root, "tracked"), "updated\n");
  await writeFile(join(root, "untracked"), "new\n");
  await writeCommit(where, "All changes", "all");
  expect(await git("status", "--porcelain")).toBe("");
  expect(await git("show", "HEAD:untracked")).toBe("new");
});

test("a changed HEAD prevents amending a commit the person has not reviewed", async () => {
  const previous = await lastCommit(where);
  await git("commit", "--allow-empty", "-m", "Another commit");
  await expect(writeCommit(where, "Wrong message", "amend", previous.head)).rejects.toThrow("last commit changed");
  expect(await git("log", "-1", "--format=%s")).toBe("Another commit");
});

test("confirmed amend records are consumed once and retain the selected repository", () => {
  const pending = { token: "one", where, text: "New message", head: "abc" };
  records.set("gitview.amend", pending);
  expect(takeAmend("other")).toBeNull();
  expect(takeAmend("one")).toEqual(pending);
  expect(takeAmend("one")).toBeNull();
});

test("Git commands target the displayed machine and preserve message arguments", async () => {
  await writeCommit({ root, on: "server" }, "--message\n\nBody with 'quotes'", "amend", (await lastCommit(where)).head);
  expect(calls.at(-1)).toMatchObject({ cmd: "git", args: ["commit", "--amend", "-m", "--message\n\nBody with 'quotes'"], options: { cwd: root, on: "server" } });
});
