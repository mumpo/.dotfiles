import { beforeEach, expect, mock, test } from "bun:test";

const exec = mock(async () => ({ code: 0, stdout: "", stderr: "Already up to date." }));
const notify = mock(() => {});
mock.module("herdr", () => ({ exec, notify, closeOverlay() {}, openOverlay() {}, setShared() {}, shared() {} }));
mock.module("./modes.js", () => ({ MODES: { files: { keys: [] } } }));
mock.module("./modkit.js", () => ({
  keyName(e) {
    const m = e.modifiers ?? {};
    return m.control || m.platform || m.alt ? null : m.shift ? e.key.toUpperCase() : e.key;
  },
  keyEvent: (key) => ({ key }),
  takeKeyboard() {},
}));
const { handleKey, chipsFor } = await import("./keys.js");
const { remoteOperation } = await import("./remote.js");

function panel(on = null) {
  const tasks = [];
  return {
    mode: "files", work: { where: { root: "/repo with spaces", on } },
    commitRunning: () => false,
    flash: { set: mock(() => {}) }, refresh: mock(() => {}), send: mock(() => {}),
    loads: { run: (_cx, _op, work) => tasks.push(work({})) },
    done: async () => { await Promise.all(tasks); },
  };
}

beforeEach(() => {
  exec.mockReset();
  exec.mockImplementation(async () => ({ code: 0, stdout: "", stderr: "Already up to date." }));
  notify.mockClear();
});

test("p pulls fast-forward only and P pushes on the displayed machine", async () => {
  const view = panel("server");
  expect(handleKey(view, { key: "p" }, {})).toBe(true);
  await view.done();
  expect(exec).toHaveBeenLastCalledWith("git", ["pull", "--ff-only"], { cwd: "/repo with spaces", on: "server", timeout: 30000 });
  expect(handleKey(view, { key: "p", modifiers: { shift: true } }, {})).toBe(true);
  await view.done();
  expect(exec).toHaveBeenLastCalledWith("git", ["push"], { cwd: "/repo with spaces", on: "server", timeout: 30000 });
  expect(view.refresh).toHaveBeenCalledTimes(2);
  expect(view.send).not.toHaveBeenCalled();
  expect(chipsFor(view).filter((chip) => ["pull", "push", "send notes"].includes(chip.label)).map((chip) => chip.caps)).toEqual([["p"], ["P"], ["ctrl-n"]]);
});

test("Ctrl+N sends notes and other modified chords stay available to the app", () => {
  const view = panel();
  expect(handleKey(view, { key: "n", modifiers: { control: true } }, {})).toBe(true);
  expect(view.send).toHaveBeenCalledTimes(1);
  for (const modifiers of [{ platform: true }, { control: true, shift: true }, { control: true, alt: true }]) {
    expect(handleKey(view, { key: "n", modifiers }, {})).toBe(false);
  }
  expect(exec).not.toHaveBeenCalled();
});

test("failures report Git's message, refresh, and allow a retry", async () => {
  exec.mockResolvedValueOnce({ code: 1, stdout: "", stderr: "fatal: Not possible to fast-forward, aborting." });
  const view = panel();
  remoteOperation(view, "pull", {});
  await view.done();
  expect(notify).toHaveBeenCalledWith({ title: "Git pull failed", body: "fatal: Not possible to fast-forward, aborting.", level: "error" });
  expect(view.remoteOperation).toBeNull();
  expect(view.refresh).toHaveBeenCalledTimes(1);
  remoteOperation(view, "push", {});
  await view.done();
  expect(exec).toHaveBeenCalledTimes(2);
});

test("repeated keys cannot overlap network operations", async () => {
  let finish;
  exec.mockImplementationOnce(() => new Promise((resolve) => { finish = resolve; }));
  const view = panel();
  remoteOperation(view, "push", {});
  remoteOperation(view, "push", {});
  remoteOperation(view, "pull", {});
  expect(exec).toHaveBeenCalledTimes(1);
  finish({ code: 0, stdout: "", stderr: "Everything up-to-date" });
  await view.done();
  expect(view.remoteOperation).toBeNull();
});

test("missing repository or active commit prevents a network operation", () => {
  const view = panel();
  view.work = null;
  remoteOperation(view, "push", {});
  expect(view.flash.set).toHaveBeenCalledWith("No repository loaded");
  view.work = { where: { root: "/repo" } };
  view.commitRunning = () => true;
  remoteOperation(view, "pull", {});
  expect(exec).not.toHaveBeenCalled();
});
