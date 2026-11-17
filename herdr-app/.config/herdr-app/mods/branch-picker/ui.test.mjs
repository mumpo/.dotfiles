// Exercise the actual view's navigation and async state without requiring GPUI
// or invoking Git in the user's workspace. Native rendering is checked separately.
import test from "node:test";
import assert from "node:assert/strict";
import vm from "node:vm";
import { readFileSync } from "node:fs";
import * as model from "./model.js";

const source = readFileSync(new URL("./main.js", import.meta.url), "utf8")
  .replace(/^import .*;\n/gm, "").replace("export default class BranchPicker", "class BranchPicker") + "\nBranchPicker";
const data = () => ({ key: "repo", top: "/repo", common: "/repo/.git", current: "refs/heads/main", sha: "abc123", remotes: ["origin"], trees: [{ ref: "refs/heads/occupied", path: "/other checkout" }],
  refs: model.parseRefs("refs/heads/main\trefs/remotes/origin/main\t[ahead 2]\torigin\trefs/heads/main\nrefs/heads/topic\nrefs/heads/occupied\nrefs/remotes/origin/topic\nrefs/tags/v1\n") });

function harness() {
  const state = { active: "space", store: {}, checking: true, tasks: [], overlays: [], calls: [], stopped: false, bindings: [], actions: {}, drawCalls: [] };
  const cx = { notify() {}, stop_propagation() { state.stopped = true; },
    bind_keys(bindings) { state.bindings.push(...bindings); },
    timer: { after() {} }, focus_handle: () => ({ focus() {} }),
    spawn(body) { const task = Promise.resolve().then(() => body(cx)); state.tasks.push(task); return task; } };
  class InputState {
    constructor(value = "") { this.text = value; this.handlers = {}; }
    static new(options) { return new InputState(options.value); }
    on(name, handler) { this.handlers[name] = handler; }
    value() { return this.text; }
    set_value(value) { this.text = value; this.handlers.change?.({}, cx); }
    focus() {}
  }
  const element = () => new Proxy({}, { get: (_target, method) => method === "when" ? (condition, fn) => condition ? fn(element()) : element()
    : method === "on_action" ? (name, handler) => { state.actions[name] = handler; return element(); }
    : (...args) => { state.drawCalls.push([method, ...args]); return element(); } });
  const api = { load: async () => data(), switchLocal: async name => state.calls.push(["switch", name]),
    create: async (...args) => state.calls.push(["create", ...args]), delete: async name => state.calls.push(["delete", name]),
    push: async (...args) => state.calls.push(["push", ...args]) };
  const Class = vm.runInNewContext(source, { ...model, View: class {}, div: element, svg: element, h_flex: element, v_flex: element,
    Popover: { new: element }, Input: { new: element }, ScrollHandle: { new: () => ({ scroll_to_item() {} }) }, InputState,
    spaces: () => [{ id: state.active, active: true, folder: "/repo", machine: null, tabs: [{ id: "tab" }] }], panes: () => [], agents: () => [],
    checking: () => state.checking, shared: key => state.store[key], setShared: (key, value) => { state.store[key] = value; },
    repository: () => api, exec() {}, nextCommand() {}, notify() {},
    openOverlay: spec => state.overlays.push(spec), run: (...args) => state.calls.push(args), theme: () => ({}), keys: () => [], hostWindow: () => ({ platform: "macos" }),
    window: { viewport_size: () => ({ width: 900, height: 700 }) },
  });
  const view = new Class(); view.init({}, cx); state.checking = false;
  view.open = true; view.target = view.context(); view.api = api; view.data = data();
  state.pressEnter = () => {
    view.picker();
    const binding = state.bindings.find(binding => binding.keystroke === "enter" && binding.context === "BranchPicker");
    assert.ok(binding, "Enter must override native input submission only in the picker");
    state.actions[binding.action]({}, cx);
  };
  return { state, view, api, cx, async flush() { while (state.tasks.length) await Promise.all(state.tasks.splice(0)); } };
}

test("menu order, filtering, favorites, and branch action availability", () => {
  const { view } = harness();
  assert.deepEqual(Array.from(view.rows().slice(0, 5), r => r.label), ["Pull", "Push…", "New Branch…", "New Worktree…", "Checkout Tag or Revision…"]);
  const branch = name => view.data.refs.find(r => r.name === name);
  view.favorite(branch("topic").ref);
  const locals = view.rows().filter(r => r.branch?.kind === "local");
  assert.equal(locals[0].label, "topic");
  view.input.set_value("tpc");
  assert.ok(view.rows().filter(r => r.branch).every(r => r.label.includes("topic")));
  assert.equal(view.branchActions(branch("main")).find(r => r.label === "Delete…").disabled, true);
  assert.equal(view.branchActions(branch("occupied")).find(r => r.label === "Delete…").disabled, true);
  assert.equal(view.branchActions(branch("origin/topic")).some(r => r.label === "Delete…"), false);
});

test("Enter opens a submenu without immediately checking out; Left returns", () => {
  const { view, state, cx } = harness();
  view.at = view.rows().findIndex(r => r.branch?.name === "topic");
  state.pressEnter();
  assert.equal(state.stopped, true);
  assert.equal(view.screen.type, "branch");
  assert.deepEqual(state.calls, []);
  view.key({ key: "left" }, cx);
  assert.equal(view.screen, null);
});

test("Ctrl+N/P move through rows, wrap, scroll, and leave plain typing alone", () => {
  const { view, cx, state } = harness();
  const scrolled = [];
  view.scroll.scroll_to_item = index => scrolled.push(index);
  view.key({ key: "n", modifiers: { control: true } }, cx);
  assert.equal(view.at, 1);
  assert.equal(state.stopped, true);
  view.key({ key: "p", modifiers: { control: true } }, cx);
  assert.equal(view.at, 0);
  view.key({ key: "p", modifiers: { control: true } }, cx);
  assert.equal(view.at, view.rows().length - 1);
  view.key({ key: "n", modifiers: { control: true } }, cx);
  assert.equal(view.at, 0);
  assert.deepEqual(scrolled, [1, 0, view.rows().length - 1, 0]);
  state.stopped = false;
  view.key({ key: "n", modifiers: {} }, cx);
  view.key({ key: "p", modifiers: { platform: true } }, cx);
  assert.equal(view.at, 0);
  assert.equal(state.stopped, false);
});

test("Enter folds and unfolds categories with either list or search focus", () => {
  const { view, cx, state } = harness();
  view.at = view.rows().findIndex(r => r.label === "Local");
  state.pressEnter();
  assert.equal(view.rows()[view.at].expanded, false);
  assert.equal(view.rows().some(r => r.branch?.kind === "local"), false);
  state.pressEnter();
  assert.equal(view.rows()[view.at].expanded, true);
  assert.equal(view.rows().some(r => r.branch?.kind === "local"), true);
  view.input.set_value("topic");
  view.at = view.rows().findIndex(r => r.label === "Local");
  assert.equal(view.rows()[view.at].expanded, true);
  state.pressEnter();
  assert.equal(view.rows()[view.at].expanded, false);
  assert.equal(view.rows().some(r => r.branch?.kind === "local"), false);
});

test("Ctrl+N/P navigate submenus and Enter activates the selected action", () => {
  const { view, cx, state } = harness();
  const branch = view.data.refs.find(r => r.name === "topic");
  view.show({ type: "branch", branch });
  view.key({ key: "n", modifiers: { control: true } }, cx);
  assert.equal(view.rows()[view.at].label, "Add favorite");
  state.pressEnter();
  assert.equal(view.preferences().favorites.includes(branch.ref), true);
  view.show({ type: "form", action: "create" });
  view.key({ key: "n", modifiers: { control: true } }, cx);
  assert.equal(view.at, 0);
});

test("Enter on Push opens confirmation, and a second Enter pushes exactly once", async () => {
  const { view, state, cx, flush } = harness();
  view.key({ key: "n", modifiers: { control: true } }, cx);
  assert.equal(view.rows()[view.at].label, "Push…");
  state.pressEnter();
  assert.equal(view.screen.action, "push");
  assert.equal(view.screen.remote, "origin");
  assert.equal(view.form.value(), "main");
  assert.deepEqual(state.calls, [], "opening confirmation must not push yet");
  state.pressEnter();
  state.pressEnter();
  await flush();
  assert.deepEqual(state.calls, [["push", "refs/heads/main", "origin", "main"]]);
  assert.equal(view.open, false);
});

test("failed push keeps confirmation open and closes after a successful retry", async () => {
  const { view, api, state, flush } = harness();
  api.push = async () => { throw new Error("Push rejected"); };
  view.push();
  state.pressEnter();
  await flush();
  assert.equal(view.open, true);
  assert.equal(view.screen.action, "push");
  assert.equal(view.form.value(), "main");
  assert.match(view.error, /Push rejected/);
  api.push = async () => {};
  view.retry();
  await flush();
  assert.equal(view.open, false);
});

function drawnProgress(view, state, label) {
  state.drawCalls = [];
  view.picker();
  assert.ok(state.drawCalls.some(([method, text]) => method === "child" && text === label), `show ${label} on the action`);
  assert.ok(state.drawCalls.some(([method, property]) => method === "loop" && property === "top"), "bounce the icon natively");
  assert.equal(state.drawCalls.some(([method, text]) => method === "child" && text === "Working…"), false);
}

test("Pull shows inline progress until completion and restores its idle state", async () => {
  const { view, state, api, flush } = harness();
  let finish;
  api.pull = () => new Promise(resolve => { finish = resolve; });
  view.pull();
  assert.equal(view.pending, "pull");
  drawnProgress(view, state, "Pulling…");
  assert.ok(state.drawCalls.some(([method, id]) => method === "id" && id === "bp-motion-row-0"));
  view.input.set_value("tag");
  drawnProgress(view, state, "Pulling…");
  await Promise.resolve();
  finish();
  await flush();
  assert.equal(view.busy, false);
  assert.equal(view.pending, null);
  state.drawCalls = [];
  view.picker();
  assert.equal(state.drawCalls.some(([method]) => method === "loop"), false);
});

test("failed actions stop bouncing and retry restores the same inline progress", async () => {
  const { view, state, api, flush } = harness();
  api.pull = async () => { throw new Error("Pull failed"); };
  view.pull(); await flush();
  assert.equal(view.pending, null);
  assert.equal(view.busy, false);
  assert.match(view.error, /Pull failed/);
  view.retry();
  drawnProgress(view, state, "Pulling…");
  await flush();
});

test("every async confirmation action uses its own progress label and bouncing icon", async t => {
  for (const [action, method, label] of [
    ["push", "push", "Pushing…"], ["delete", "delete", "Deleting…"], ["rename", "rename", "Renaming…"],
    ["revision", "detach", "Checking out…"], ["create", "create", "Creating branch…"],
    ["tracking", "create", "Creating branch…"], ["worktree-tracking", "create", "Creating worktree branch…"],
  ]) await t.test(action, async () => {
    const { view, state, api, flush } = harness();
    let finish;
    api[method] = () => new Promise(resolve => { finish = resolve; });
    view.show({ type: "form", action, remote: "origin", branch: view.data.refs.find(r => r.name === "topic") }, "topic-new");
    state.pressEnter();
    drawnProgress(view, state, label);
    assert.ok(state.drawCalls.some(([method, id]) => method === "id" && id === "bp-motion-submit"));
    await Promise.resolve(); finish(); await flush();
    assert.equal(view.pending, null);
  });
});

test("checkout animates its submenu action, and repository refresh animates its header", async () => {
  const { view, state, api, flush } = harness();
  let finish;
  api.switchLocal = () => new Promise(resolve => { finish = resolve; });
  const branch = view.data.refs.find(r => r.name === "topic");
  view.show({ type: "branch", branch });
  state.pressEnter();
  drawnProgress(view, state, "Switching…");
  await Promise.resolve(); finish(); await flush();
  view.open = true;
  view.loading = true;
  drawnProgress(view, state, "Refreshing…");
  assert.ok(state.drawCalls.some(([method, id]) => method === "id" && id === "bp-motion-refresh"));
});

test("remote checkout asks for a name and only records a successful checkout", async () => {
  const { view, state, flush } = harness();
  view.checkout(view.data.refs.find(r => r.name === "origin/topic"));
  assert.equal(view.screen.action, "tracking");
  assert.equal(view.form.value(), "topic");
  assert.deepEqual(state.calls, []);
  view.submit(); view.submit();
  await flush();
  assert.equal(state.calls.length, 1);
  assert.deepEqual(state.calls[0], ["create", "topic", "refs/remotes/origin/topic", true]);
  assert.equal(view.open, false);
  assert.equal(view.preferences().recent[0], "refs/heads/topic");
});

test("checkout failures stay visible, preserve recents, and can be retried", async () => {
  const { view, api, flush } = harness();
  api.switchLocal = async () => { throw new Error("Local changes would be overwritten"); };
  view.checkout(view.data.refs.find(r => r.name === "topic")); await flush();
  assert.match(view.error, /overwritten/); assert.equal(view.open, true);
  assert.equal(view.preferences().recent.length, 0);
  api.switchLocal = async () => {};
  view.retry(); await flush();
  assert.equal(view.open, false);
  assert.equal(view.preferences().recent[0], "refs/heads/topic");
});

test("delete requires a confirmation screen; worktree reuses the native dialog", async () => {
  const { view, state, flush } = harness();
  const branch = view.data.refs.find(r => r.name === "topic");
  view.branchActions(branch).find(r => r.label === "Delete…").go();
  assert.equal(view.screen.action, "delete"); assert.deepEqual(state.calls, []);
  view.submit(); await flush();
  assert.deepEqual(state.calls[0], ["delete", "topic"]);
  view.worktree(branch);
  assert.equal(state.overlays[0].mod, "worktree");
  assert.equal(state.overlays[0].props.branch, "topic");
});

test("closing or changing spaces invalidates delayed repository reads", async () => {
  const { view, api, state, flush } = harness();
  let resolve;
  api.load = () => new Promise(done => { resolve = done; });
  view.reload();
  // Start the async load, then change spaces before it completes.
  await Promise.resolve();
  state.active = "different-space";
  view.render();
  resolve({ ...data(), key: "stale" });
  await flush();
  assert.equal(view.open, false);
  assert.equal(view.data.key, "repo");
});
