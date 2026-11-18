import { View, div, svg } from "gpui-kit";
import { h_flex, v_flex, Popover, Input, InputState, ScrollHandle } from "gpui-base";
import { spaces, panes, agents, theme, run, window as hostWindow, keys, exec, nextCommand, shared, setShared, openOverlay, notify, checking } from "herdr";
import { repository } from "./git.js";
import { ordered, recentRefs, remember, trackingName, score } from "./model.js";

const STORE = "branch-picker.repositories";
const GROUPS = [["Recent", null], ["Local", "local"], ["Remote", "remote"], ["Tags", "tag"]];
const icon = (name, size = 14) => svg(`mods/branch-picker/${name}.svg`).size(size).flex_none();
const PROGRESS = {
  pull: { label: "Pulling…", glyph: "down" },
  push: { label: "Pushing…", glyph: "up" },
  checkout: { label: "Switching…", glyph: "branch" },
  revision: { label: "Checking out…", glyph: "tag" },
  create: { label: "Creating branch…", glyph: "plus" },
  tracking: { label: "Creating branch…", glyph: "branch" },
  "worktree-tracking": { label: "Creating worktree branch…", glyph: "worktree" },
  rename: { label: "Renaming…", glyph: "branch" },
  delete: { label: "Deleting…", glyph: "branch" },
};

// Animate a positioned child inside a fixed box, so the row never shifts.
const actionIcon = (name, active, id) => div().size(14).flex_none().relative()
  .child(div().id(`bp-motion-${id}`).size(14).absolute().left(0).top(0)
    .when(active, el => el.loop("top", { from: -2, to: 2, period: 600 }))
    .child(icon(name)));

// One always-mounted footer owns the picker and its tasks. Native Popover measures
// its trigger for both mouse and command activation; no cached screen coordinates.
export default class BranchPicker extends View {
  init(_props, cx) {
    this.cx = cx;
    this.open = false;
    this.busy = false;
    this.pending = null;
    this.loading = false;
    this.error = "";
    this.at = 0;
    this.query = "";
    this.searchCollapsed = {};
    this.screen = null;
    this.retry = null;
    this.collapsed = { Recent: true, Remote: true, Tags: true };
    this.generation = 0;
    this.scroll = ScrollHandle.new();
    this.handle = cx.focus_handle();
    // Bind Enter at the picker context so the search input's native Submit
    // action cannot consume it before the selected menu row is activated.
    cx.bind_keys([{ keystroke: "enter", action: "branch-picker.activate", context: "BranchPicker" }]);
    this.input = InputState.new({ placeholder: "Search branches and actions" });
    this.input.on("change", () => { this.query = this.input.value(); this.searchCollapsed = {}; this.at = 0; cx.notify(); });
    this.form = InputState.new({ placeholder: "Name or revision" });
    this.form.on("change", () => { this.error = ""; cx.notify(); });
    if (!checking()) cx.spawn(async () => {
      for (;;) {
        const command = await nextCommand();
        if (command === "toggle") this.change(!this.open);
        cx.notify();
      }
    });
  }

  context() {
    const space = spaces().find(s => s.active);
    if (!space) return null;
    const tabs = new Set(space.tabs.map(t => t.id));
    const folder = panes().find(p => tabs.has(p.tab) && p.cwd)?.cwd || space.folder;
    return { space: space.id, folder, on: space.machine ?? null };
  }

  change(open) {
    if (open === this.open || (open && this.busy)) return;
    this.open = open;
    this.generation++;
    this.error = "";
    this.screen = null;
    this.retry = null;
    if (open) {
      this.target = this.context();
      this.query = "";
      this.input.set_value("");
      this.at = 0;
      this.data = null;
      this.reload();
      this.focusInput();
    }
    this.cx.notify();
  }

  focusInput(form = false) {
    // Focus after mounting the native popover/input, rather than during its press.
    this.cx.timer.after(50, () => { if (this.open) (form ? this.form : this.input).focus(); });
  }

  preferences() {
    return (shared(STORE) || {})[this.data?.key] || { favorites: [], recent: [] };
  }

  save(values, key = this.data?.key) {
    if (!key) return;
    const all = shared(STORE) || {};
    setShared(STORE, { ...all, [key]: { favorites: [], recent: [], ...all[key], ...values } });
  }

  favorite(ref) {
    const { favorites } = this.preferences();
    this.save({ favorites: favorites.includes(ref) ? favorites.filter(r => r !== ref) : [...favorites, ref] });
  }

  reload() {
    if (!this.target?.folder) { this.error = "Open a space in a Git repository first."; this.loading = false; this.cx.notify(); return; }
    const generation = this.generation;
    this.loading = true;
    this.error = "";
    this.retry = null;
    this.api = repository(exec, this.target.folder, this.target.on);
    const api = this.api;
    this.cx.spawn(async cx => {
      try {
        const data = await api.load();
        if (generation !== this.generation) return;
        this.data = data;
      } catch (e) { if (generation === this.generation) this.error = String(e.message || e); }
      if (generation !== this.generation) return;
      this.loading = false;
      cx.notify();
    });
    this.cx.notify();
  }

  show(screen, value = "") {
    this.screen = screen;
    this.error = "";
    this.retry = null;
    this.at = 0;
    this.form.set_value(value);
    this.cx.notify();
    if (screen.type === "form") this.focusInput(true);
    else this.handle.focus();
  }

  back() {
    if (this.busy) return;
    const parent = this.screen?.parent;
    this.screen = parent || null;
    this.error = "";
    this.retry = null;
    this.at = 0;
    this.cx.notify();
    if (parent) this.handle.focus(); else this.focusInput();
  }

  action(label, go, extra = {}) { return { label, go, ...extra }; }

  rows() {
    if (!this.data) return [];
    if (this.screen?.type === "form") return [];
    if (this.screen?.type === "branch") return this.branchActions(this.screen.branch);
    if (this.screen?.type === "remotes") return this.data.remotes.map(remote => this.action(remote, () => this.pushForm(remote)));
    const actions = [
      this.action("Pull", () => this.pull(), { glyph: "down", actionId: "pull" }),
      this.action("Push…", () => this.push(), { glyph: "up" }),
      this.action("New Branch…", () => this.newBranch(), { glyph: "plus" }),
      this.action("New Worktree…", () => this.worktree(), { glyph: "worktree" }),
      this.action("Checkout Tag or Revision…", () => this.revision(), { glyph: "tag" }),
    ];
    const matches = actions.filter(a => score(this.query, a.label) !== null || (this.busy && a.actionId === this.pending));
    const { favorites, recent } = this.preferences();
    const refs = ordered(this.data.refs, this.query, favorites);
    const rows = [...matches];
    for (const [label, kind] of GROUPS) {
      const list = kind ? refs.filter(r => r.kind === kind) : recentRefs(recent, refs);
      if (this.query && !list.length) continue;
      const collapsed = this.query.trim() ? this.searchCollapsed : this.collapsed;
      const expanded = !collapsed[label];
      rows.push(this.action(label, () => { collapsed[label] = expanded; this.cx.notify(); }, { group: true, expanded, count: list.length }));
      if (expanded) for (const branch of list) rows.push(this.action(branch.name, () => this.show({ type: "branch", branch }), { branch }));
    }
    return rows;
  }

  branchActions(branch) {
    const tree = this.data.trees.find(t => t.ref === branch.ref && t.path !== this.data.top);
    const current = branch.ref === this.data.current;
    const local = branch.kind === "local";
    const favorite = this.preferences().favorites.includes(branch.ref);
    const rows = [this.action(tree ? "Open worktree" : branch.kind === "tag" ? "Checkout tag (detached HEAD)…" : current ? "Current branch" : "Checkout", () => {
      if (tree) this.openTree(tree);
      else if (branch.kind === "tag") this.revision(branch.ref);
      else if (!current) this.checkout(branch);
    }, { disabled: current && !tree, actionId: "checkout" })];
    rows.push(this.action(favorite ? "Remove favorite" : "Add favorite", () => this.favorite(branch.ref), { glyph: "star" }));
    rows.push(this.action("New branch from here…", () => this.newBranch(branch)));
    if (branch.kind !== "tag") rows.push(this.action(tree || current ? "Open worktree" : "New worktree here…", () => tree ? this.openTree(tree) : current ? this.openTree({ path: this.data.top }) : this.worktree(branch)));
    if (local) {
      rows.push(this.action("Rename…", () => this.show({ type: "form", action: "rename", branch, title: "Rename branch", parent: this.screen }, branch.name)));
      rows.push(this.action("Delete…", () => this.show({ type: "form", action: "delete", branch, title: `Delete ${branch.name}?`, detail: "Git will refuse to delete an unmerged branch.", parent: this.screen }), { disabled: current || Boolean(tree), danger: true }));
    }
    return rows;
  }

  activate(row) { if (!this.busy && !this.loading && row && !row.disabled) { row.go(); this.cx.notify(); } }

  perform(label, task, { close = false, rememberBranch = null, after = null, activity = this.screen?.action || "checkout" } = {}) {
    if (this.busy || this.loading || !this.data) return;
    this.retry = () => this.perform(label, task, { close, rememberBranch, after, activity });
    this.busy = true;
    this.pending = activity;
    this.error = "";
    const generation = this.generation, key = this.data.key, target = this.target;
    this.cx.notify();
    this.cx.spawn(async cx => {
      try {
        await task();
        if (rememberBranch) {
          const old = (shared(STORE) || {})[key] || {};
          this.save({ recent: remember(old.recent || [], rememberBranch) }, key);
        }
        notify({ title: label, level: "success", timeout: 2500 });
        this.busy = false;
        this.pending = null;
        if (generation === this.generation && this.open) {
          if (close || after) this.change(false);
          else { this.screen = null; this.reload(); this.focusInput(); }
        }
        if (after) after(target);
      } catch (e) {
        this.busy = false;
        this.pending = null;
        if (generation === this.generation && this.open) this.error = String(e.message || e);
        else notify({ title: label, body: String(e.message || e), level: "error" });
      }
      cx.notify();
    });
  }

  checkout(branch) {
    if (branch.kind === "remote") {
      this.show({ type: "form", action: "tracking", branch, title: "Checkout remote branch", detail: `Create a local branch tracking ${branch.name}`, parent: this.screen }, trackingName(branch, this.data.remotes));
      return;
    }
    const api = this.api;
    this.perform(`Switched to ${branch.name}`, () => api.switchLocal(branch.name), { close: true, rememberBranch: branch.ref });
  }

  newBranch(branch = null) {
    this.show({ type: "form", action: "create", branch, title: "New branch", detail: `Create and switch from ${branch?.name || "HEAD"}`, parent: this.screen });
  }

  revision(value = "") {
    this.show({ type: "form", action: "revision", title: "Checkout tag or revision", detail: "This checks out a commit in detached HEAD mode. Your existing branches remain available.", parent: this.screen }, value);
  }

  worktree(branch = null) {
    if (branch?.kind === "remote") {
      this.show({ type: "form", action: "worktree-tracking", branch, title: "New worktree", detail: `Create a local branch tracking ${branch.name}`, parent: this.screen }, trackingName(branch, this.data.remotes));
      return;
    }
    const target = this.target;
    this.change(false);
    openOverlay({ mod: "worktree", kind: "dialog", width: 560, height: 480,
      props: { space: target.space, folder: target.folder, machine: target.on, action: "new", ...(branch ? { branch: branch.name } : {}) } });
  }

  openTree(tree) {
    const target = this.target;
    const existing = spaces().find(s => s.machine === target.on && (s.folder === tree.path || panes().some(p => p.cwd === tree.path && s.tabs.some(t => t.id === p.tab))));
    this.change(false);
    if (existing) run("space.select", { id: existing.id });
    else run("space.new", { folder: tree.path, machine: target.on ?? "" });
  }

  pull() {
    const current = this.data.refs.find(r => r.ref === this.data.current);
    if (!current?.upstream) { this.error = "The current branch has no upstream. Push it with tracking first."; this.cx.notify(); return; }
    const api = this.api;
    this.perform("Pull completed", () => api.pull(), { activity: "pull" });
  }

  push() {
    if (!this.data.current) { this.error = "Check out a branch before pushing."; return; }
    const current = this.data.refs.find(r => r.ref === this.data.current);
    if (current?.remote && current.remote !== ".") return this.pushForm(current.remote, current.remoteRef?.replace(/^refs\/heads\//, ""));
    if (!this.data.remotes.length) { this.error = "This repository has no remotes."; return; }
    if (this.data.remotes.length === 1) this.pushForm(this.data.remotes[0]);
    else this.show({ type: "remotes", title: "Choose a push remote" });
  }

  pushForm(remote, name) {
    this.show({ type: "form", action: "push", remote, title: `Push to ${remote}`, detail: "Confirm the destination branch. This is a normal push; tracking is set on success.", parent: { type: "remotes", title: "Choose a push remote" } }, name || this.data.current.slice(11));
  }

  submit() {
    if (this.busy || this.screen?.type !== "form") return;
    const screen = this.screen, name = this.form.value(), api = this.api;
    const current = this.data.current;
    if (screen.action === "revision") {
      this.perform("Checked out detached HEAD", () => api.detach(name), { close: true });
    } else if (screen.action === "delete") {
      this.perform(`Deleted ${screen.branch.name}`, () => api.delete(screen.branch.name));
    } else if (screen.action === "rename") {
      this.perform(`Renamed branch to ${name}`, () => api.rename(screen.branch.name, name));
    } else if (screen.action === "push") {
      this.perform(`Pushed to ${screen.remote}/${name}`, () => api.push(current, screen.remote, name), { close: true });
    } else if (screen.action === "worktree-tracking") {
      this.perform(`Created ${name}`, () => api.create(name, screen.branch.ref, true, false), {
        after: target => openOverlay({ mod: "worktree", kind: "dialog", width: 560, height: 480, props: { space: target.space, folder: target.folder, machine: target.on, action: "new", branch: name } }),
      });
    } else {
      this.perform(`Switched to ${name}`, () => api.create(name, screen.branch?.ref || null, screen.action === "tracking"), { close: true, rememberBranch: `refs/heads/${name}` });
    }
  }

  accept(cx) {
    if (!this.open) return;
    cx.stop_propagation();
    if (this.screen?.type === "form") this.submit();
    else this.activate(this.rows()[this.at]);
    cx.notify();
  }

  key(event, cx) {
    if (!this.open) return;
    const control = event.modifiers?.control && !event.modifiers?.platform && !event.modifiers?.alt;
    const k = control && event.key === "n" ? "down" : control && event.key === "p" ? "up" : event.key;
    if (k === "escape" || (k === "left" && this.screen && this.screen.type !== "form")) {
      if (this.screen) this.back(); else this.change(false);
    } else if (this.screen?.type === "form") return;
    else if (k === "down" || k === "up" || k === "right") {
      const rows = this.rows();
      if (k === "down" || k === "up") {
        this.at = rows.length ? (this.at + rows.length + (k === "down" ? 1 : -1)) % rows.length : 0;
        this.scroll.scroll_to_item(this.at);
      } else this.activate(rows[this.at]);
    } else return;
    cx.stop_propagation();
    cx.notify();
  }

  picker() {
    const t = theme(), rows = this.rows();
    const viewport = window.viewport_size();
    const listHeight = Math.max(64, Math.min(352, viewport.height - 240));
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const form = this.screen?.type === "form";
    const progress = PROGRESS[this.pending];
    return v_flex().id("bp-picker").w(Math.min(480, viewport.width - 24)).max_h(Math.max(120, viewport.height - 48)).overflow_y_scrollbar().p(12).gap(8).bg(t.popover).rounded(10).border_1().border_color(t.border).shadow_lg()
      .text_size(13).text_color(t.foreground).track_focus(this.handle).key_context("BranchPicker")
      .on_action("branch-picker.activate", (_event, cx) => this.accept(cx))
      .on_key_down((e, cx) => this.key(e, cx))
      .child(h_flex().items_center().gap(8)
        .when(Boolean(this.screen), el => el.child(div().id("bp-back").px(6).py(4).cursor_pointer().hover(s => s.bg(t.hover)).on_click(() => this.back()).child("‹")))
        .child(div().flex_1().truncate().font_semibold().child(this.screen?.title || this.screen?.branch?.name || this.data?.current?.slice(11) || (this.data?.sha ? `Detached HEAD · ${this.data.sha}` : "Git branches")))
        .child(h_flex().id("bp-refresh").px(6).py(4).gap(6).items_center().text_color(t.dim).cursor_pointer()
          .on_click(() => { if (!this.busy && !this.loading) { this.screen = null; this.reload(); this.focusInput(); } })
          .child(actionIcon("refresh", this.loading, "refresh"))
          .child(this.loading ? this.data ? "Refreshing…" : "Loading…" : "Refresh"))
        .child(div().id("bp-close").px(6).py(4).text_color(t.dim).cursor_pointer().on_click(() => this.change(false)).child("Esc")))
      .when(!this.screen, el => el.child(h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(7).border_1().border_color(t.input)
        .child(icon("search")).child(Input.new(this.input).flex_1().h_full().text_color(t.foreground))))
      .when(Boolean(this.screen?.detail), el => el.child(div().px(6).text_color(t.muted).child(this.screen?.detail || "")))
      .when(form && this.screen?.action !== "delete", el => el.child(h_flex().h(36).px(10).rounded(7).border_1().border_color(t.input).child(Input.new(this.form).flex_1().text_color(t.foreground))))
      .when(form, el => el.child(h_flex().id("bp-submit").px(12).py(8).gap(8).items_center().rounded(6).cursor_pointer().bg(this.screen?.action === "delete" ? t.blocked : t.accent).text_color(t.accent_foreground)
        .on_click(() => this.submit())
        .child(actionIcon((progress || PROGRESS[this.screen?.action])?.glyph || "branch", this.busy, "submit"))
        .child(this.busy ? progress?.label || "Running…" : this.screen?.action === "delete" ? "Delete branch" : this.screen?.action === "push" ? `Push to ${this.screen.remote}/${this.form.value()}` : this.screen?.action === "revision" ? "Checkout detached HEAD" : "Confirm")))
      .when(!form, el => el.child(v_flex().id("bp-list").h(this.screen ? Math.max(64, Math.min(listHeight, rows.length * 32)) : listHeight).min_h(0).overflow_y_scrollbar().track_scroll(this.scroll)
        .children(rows.map((row, index) => this.row(row, index, t)))))
      .when(!this.loading && !form && !rows.length && Boolean(this.data), el => el.child(div().px(6).text_color(t.dim).child("No matches")))
      .when(Boolean(this.error), el => el.child(v_flex().gap(6).p(8).rounded(6).bg(t.background)
        .child(div().text_color(t.blocked).child(this.error))
        .child(div().id("bp-retry").text_color(t.accent).cursor_pointer().on_click(() => { if (!this.busy) this.retry ? this.retry() : this.reload(); }).child("Retry"))))
      .child(div().px(6).text_size(10.5).text_color(t.dim).child("↑ ↓ / Ctrl+N P navigate   ↵ activate / fold   ← back"));
  }

  row(row, index, t) {
    const branch = row.branch;
    const favorite = branch && this.preferences().favorites.includes(branch.ref);
    const current = branch?.ref === this.data.current;
    const elsewhere = branch && this.data.trees.some(tree => tree.ref === branch.ref && tree.path !== this.data.top);
    const active = this.busy && row.actionId === this.pending;
    const progress = active ? PROGRESS[this.pending] : null;
    return h_flex().id(`bp-row-${index}`).h(32).flex_none().px(8).gap(8).items_center().rounded(6).cursor_pointer()
      .when(index === this.at, el => el.bg(t.selected))
      .hover(s => s.bg(t.hover))
      .when(row.group, el => el.mt(3).text_color(t.muted))
      .when(row.disabled || ((this.busy || this.loading) && !active), el => el.text_color(t.dim))
      .on_click(() => this.activate(row))
      .child(row.group ? div().w(14).child(row.expanded ? "⌄" : "›") : branch ? div().id(`bp-star-${index}`).w(14).text_color(favorite ? t.ansi3 : t.dim)
        .on_click((_e, cx) => { cx.stop_propagation(); if (!this.busy && !this.loading) this.favorite(branch.ref); }).child(favorite ? "★" : "☆") : actionIcon(row.glyph || "branch", active, `row-${index}`))
      .child(div().flex_1().truncate().when(Boolean(current), el => el.font_semibold()).when(Boolean(row.danger), el => el.text_color(t.blocked)).child(`${current ? "✓ " : ""}${progress?.label || row.label}`))
      .when(Boolean(branch?.ahead || branch?.behind), el => el.child(div().text_size(11).text_color(t.muted).child(`${branch?.behind ? `↓${branch.behind} ` : ""}${branch?.ahead ? `↑${branch.ahead}` : ""}`)))
      .when(Boolean(branch?.upstream), el => el.child(div().max_w(120).truncate().text_size(11).text_color(t.dim).child(branch?.upstream.replace(/^refs\/remotes\//, "") || "")))
      .when(Boolean(elsewhere), el => el.child(icon("worktree", 12).text_color(t.dim)))
      .when(Boolean(row.group), el => el.child(div().text_color(t.dim).child(String(row.count))))
      .when(Boolean(branch), el => el.child(div().text_color(t.dim).child("›")));
  }

  render() {
    const t = theme(), space = spaces().find(s => s.active), list = agents();
    // Space changes invalidate in-flight reads without retargeting an operation.
    if (this.open && this.target?.space !== space?.id) { this.open = false; this.generation++; }
    // A check also materializes the picker, which is otherwise deferred by Popover.
    if (checking()) return this.picker();
    const label = (name, text) => h_flex().gap(6).items_center().child(svg(`mods/workspace-chrome/${name}.svg`).size(13)).child(text);
    const binding = keys().find(k => k.section === "global" && k.action === "mod.open:workspace-palette");
    const hint = binding ? binding.keys.split("-").map(k => ({ cmd: hostWindow()?.platform === "macos" ? "⌘" : "Ctrl+", shift: "⇧", alt: "⌥", ctrl: "⌃" })[k] || k.toUpperCase()).join("") + "  commands" : "commands";
    const needs = list.filter(a => a.status === "blocked").length;
    return h_flex().size_full().px(14).gap(16).items_center().bg(t.chrome).border_t(1).border_color(t.border).text_size(11.8).text_color(t.muted)
      .child(label(space?.machine ? "server" : "monitor", space?.machine || "This computer"))
      .child(Popover.new("branch-picker-popover").open(this.open).anchor("bottom_left")
        .on_open_change(open => this.change(open))
        .trigger(div().id("branch-picker-trigger").px(5).py(3).rounded(4).cursor_pointer().hover(s => s.bg(t.hover).text_color(t.foreground)).child(label("branch", space?.branch || "Git branches")))
        .content(this.picker()))
      .child(h_flex().gap(6).items_center().child(div().size(6).rounded(3).bg(t.dim)).child(`${list.length} agents`)
        .when(needs > 0, el => el.child(div().text_color(t.blocked).child(`· ${needs} needs you`))))
      .child(div().flex_1())
      .child(div().id("palette").text_color(t.dim).cursor_pointer().on_click(() => run("mod.open", { name: "workspace-palette" })).child(hint));
  }
}
