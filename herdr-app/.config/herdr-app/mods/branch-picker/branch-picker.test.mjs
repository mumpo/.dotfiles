import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync } from "node:fs";
import { join } from "node:path";
import { repository } from "./git.js";
import { ordered, parseRefs, parseWorktrees, recentRefs, remember, trackingName } from "./model.js";

const env = { ...process.env, GIT_CONFIG_GLOBAL: "/dev/null", GIT_CONFIG_NOSYSTEM: "1",
  GIT_AUTHOR_NAME: "Branch picker test", GIT_AUTHOR_EMAIL: "test@example.invalid",
  GIT_COMMITTER_NAME: "Branch picker test", GIT_COMMITTER_EMAIL: "test@example.invalid" };
function execute(command, args, { cwd }) {
  const result = spawnSync(command, args, { cwd, env, encoding: "utf8" });
  if (result.error) throw result.error;
  return { code: result.status, stdout: result.stdout, stderr: result.stderr };
}
function git(cwd, ...args) {
  const result = execute("git", args, { cwd });
  assert.equal(result.code, 0, result.stderr);
  return result.stdout.trim();
}
function fixture(t) {
  const folder = mkdtempSync("/private/tmp/herdr-branch-test-");
  t.after(() => rmSync(folder, { recursive: true, force: true }));
  git(folder, "init", "-b", "main");
  git(folder, "config", "commit.gpgsign", "false");
  git(folder, "config", "core.hooksPath", "/dev/null");
  writeFileSync(join(folder, "file.txt"), "base\n");
  git(folder, "add", ".");
  git(folder, "commit", "-m", "initial");
  return { folder, api: repository(execute, folder) };
}
function commit(folder, text) {
  writeFileSync(join(folder, "file.txt"), text);
  git(folder, "add", "."); git(folder, "commit", "-m", text.trim());
}

test("refs keep full identities, upstream counts and remote/tag distinctions", () => {
  const refs = parseRefs("refs/heads/main\trefs/remotes/upstream/main\t[ahead 2, behind 123]\tupstream\trefs/heads/main\nrefs/remotes/upstream/HEAD\t\t\t\t\nrefs/remotes/upstream/topic/你好\t\t\t\t\nrefs/tags/main\t\t\t\t\n");
  assert.equal(refs.length, 3);
  assert.equal(refs[0].ahead, 2); assert.equal(refs[0].behind, 123);
  assert.equal(refs[2].kind, "tag");
  assert.equal(trackingName(refs[1], ["up", "upstream"]), "topic/你好");
  assert.deepEqual(parseWorktrees("worktree /tmp/a path/你好\0HEAD abcd\0branch refs/heads/main\0\0"), [{ path: "/tmp/a path/你好", ref: "refs/heads/main" }]);
});

test("favorites stay first, fuzzy search filters, recents are unique and bounded", () => {
  const refs = parseRefs("refs/heads/main\nrefs/heads/topic/a\nrefs/heads/feature-b\n");
  assert.equal(ordered(refs, "", ["refs/heads/topic/a"])[0].name, "topic/a");
  assert.deepEqual(ordered(refs, "ftb").map(r => r.name), ["feature-b"]);
  const recent = remember(Array.from({ length: 12 }, (_, i) => `ref${i}`), "ref3");
  assert.equal(recent.length, 10); assert.equal(recent.filter(r => r === "ref3").length, 1);
  assert.deepEqual(recentRefs(["missing", "refs/heads/main"], refs), [refs[0]]);
});

test("branch names remain literal argv, invalid names fail before mutation", async t => {
  const { folder, api } = fixture(t);
  const name = "topic/$(touch-pwned)";
  await api.create(name);
  assert.equal((await api.load()).current, `refs/heads/${name}`);
  assert.equal(existsSync(join(folder, "touch-pwned")), false);
  for (const invalid of ["--force", "bad name", "@{-1}", "name ", "a..b", ""]) await assert.rejects(api.create(invalid));
  assert.equal((await api.load()).current, `refs/heads/${name}`);
  await api.rename(name, "topic/你好");
  assert.equal((await api.load()).current, "refs/heads/topic/你好");
  await api.switchLocal("main");
  await api.delete("topic/你好");
});

test("dirty checkout preserves edits; safe deletion refuses unmerged history", async t => {
  const { folder, api } = fixture(t);
  await api.create("other"); commit(folder, "other\n");
  await api.switchLocal("main");
  writeFileSync(join(folder, "file.txt"), "uncommitted\n");
  await assert.rejects(api.switchLocal("other"), /overwritten|changes/i);
  assert.equal(readFileSync(join(folder, "file.txt"), "utf8"), "uncommitted\n");
  assert.equal((await api.load()).current, "refs/heads/main");
  await assert.rejects(api.delete("other"), /not fully merged/i);
  assert.ok((await api.load()).refs.find(r => r.name === "other"));
});

test("tag checkout detaches; option-like and missing revisions cannot change HEAD", async t => {
  const { folder, api } = fixture(t);
  git(folder, "tag", "v1");
  await api.detach("refs/tags/v1");
  assert.equal((await api.load()).current, null);
  for (const revision of ["--help", "missing", ""]) await assert.rejects(api.detach(revision));
  assert.equal((await api.load()).sha, git(folder, "rev-parse", "--short", "HEAD"));
});

test("linked worktrees share identity and Git refuses switching an occupied branch", async t => {
  const { folder, api } = fixture(t);
  const path = join(folder, "linked checkout 你好");
  git(folder, "worktree", "add", "-b", "occupied", path);
  const linked = repository(execute, path);
  const [one, two] = await Promise.all([api.load(), linked.load()]);
  assert.equal(one.key, two.key);
  assert.equal(one.trees.find(tree => tree.ref === "refs/heads/occupied").path, path);
  await assert.rejects(api.switchLocal("occupied"), /already.*(worktree|used)|checked out/i);
});

test("remote tracking, explicit push and fast-forward-only pull use local remotes", async t => {
  const { folder, api } = fixture(t);
  const remote = join(folder, "origin.git"), peer = join(folder, "peer");
  git(folder, "init", "--bare", "-b", "main", remote);
  git(folder, "remote", "add", "origin", remote);
  await api.push("refs/heads/main", "origin", "main");
  git(folder, "clone", remote, peer);
  git(peer, "config", "commit.gpgsign", "false");
  commit(peer, "upstream\n"); git(peer, "push");
  await api.pull();
  assert.equal(readFileSync(join(folder, "file.txt"), "utf8"), "upstream\n");
  await api.create("topic/remote");
  await api.push("refs/heads/topic/remote", "origin", "topic/remote");
  await api.switchLocal("main"); await api.delete("topic/remote");
  await api.create("tracking-local", "refs/remotes/origin/topic/remote", true);
  assert.equal((await api.load()).refs.find(r => r.name === "tracking-local").upstream, "refs/remotes/origin/topic/remote");
  await api.switchLocal("main");
  await api.create("worktree-local", "refs/remotes/origin/topic/remote", true, false);
  assert.equal((await api.load()).current, "refs/heads/main");
  commit(folder, "local divergence\n");
  commit(peer, "remote divergence\n"); git(peer, "push");
  const before = git(folder, "rev-parse", "HEAD");
  await assert.rejects(api.pull(), /fast.forward|diverg/i);
  assert.equal(git(folder, "rev-parse", "HEAD"), before);
  await assert.rejects(api.push("refs/heads/main", "origin", "main"), /rejected|fetch first/i);
});

test("empty, non-Git and unreachable contexts report useful states or errors", async t => {
  const empty = mkdtempSync("/private/tmp/herdr-branch-empty-");
  t.after(() => rmSync(empty, { recursive: true, force: true }));
  await assert.rejects(repository(execute, empty).load(), /not a git repository/i);
  git(empty, "init", "-b", "main");
  const data = await repository(execute, empty).load();
  assert.equal(data.sha, "unborn"); assert.deepEqual(data.refs, []);
  await assert.rejects(repository(async () => { throw new Error("Machine unavailable"); }, "/repo", "remote").load(), /Machine unavailable/);
});
