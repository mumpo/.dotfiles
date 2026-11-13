// Fuzzy-find a ~/dev/<owner>/<repo> folder and open a new space there.
// Type to filter, ↑/↓ and Enter to open, Esc to leave.

import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, exec, home, theme, props, closeOverlay } from "herdr";

const ROOT = "dev";
const VISIBLE = 10;
const ROW = 30;

// Subsequence match: every query char in order. Higher is better; null is no match.
// Consecutive runs and matches at the start of a path segment score extra, shorter paths win ties.
function score(query, text) {
  const q = query.toLowerCase(), s = text.toLowerCase();
  let at = 0, total = 0, run = 0;
  for (let i = 0; i < s.length && at < q.length; i++) {
    if (s[i] !== q[at]) { run = 0; continue; }
    run++;
    total += 1 + run * 2 + (i === 0 || s[i - 1] === "/" || s[i - 1] === "-" ? 5 : 0);
    at++;
  }
  return at === q.length ? total - s.length * 0.01 : null;
}

export default class ProjectPicker extends View {
  init(_props, cx) {
    this.filter = "";
    this.at = 0;
    this.projects = [];
    this.input = InputState.new({ placeholder: "Open project…" });
    this.input.on("change", (_e, cx) => {
      this.filter = this.input.value();
      this.at = 0;
      cx.notify();
    });
    this.input.on("submit", (_e, cx) => this.go(this.rows()[this.at]));
    this.input.focus();
    cx.timer.after(600, () => this.input.focus());
    this.handle = cx.focus_handle();
    cx.spawn(async (cx) => {
      try {
        const base = `${home()}/${ROOT}`;
        const r = await exec("find", [base, "-mindepth", "2", "-maxdepth", "2", "-type", "d"]);
        if (r.code === 0) {
          this.projects = r.stdout.split("\n").filter(Boolean).sort()
            .map((path) => ({ path, name: path.slice(base.length + 1) }));
        }
      } catch {}
      cx.notify();
    });
  }

  close() {
    closeOverlay(props().overlay);
  }

  rows() {
    if (!this.filter) return this.projects;
    return this.projects
      .map((p) => ({ p, s: score(this.filter, p.name) }))
      .filter((x) => x.s !== null)
      .sort((a, b) => b.s - a.s)
      .map((x) => x.p);
  }

  go(p) {
    if (!p) return;
    this.close();
    run("space.new", { folder: p.path });
  }

  render() {
    const t = theme();
    const rows = this.rows();
    this.at = Math.max(0, Math.min(this.at, rows.length - 1));
    const start = Math.max(0, Math.min(this.at - Math.floor(VISIBLE / 2), rows.length - VISIBLE));
    const shown = rows.slice(start, start + VISIBLE);

    return v_flex()
      .id("project-picker")
      .track_focus(this.handle)
      .w_full()
      .min_h(0)
      .p(18)
      .gap(10)
      .bg(t.popover)
      .text_size(13)
      .on_key_down((e, cx) => {
        const k = e.key;
        if (k === "escape") return this.close();
        if (!rows.length) return;
        if (k === "down" || (k === "n" && e.modifiers.control)) this.at = (this.at + 1) % rows.length;
        else if (k === "up" || (k === "p" && e.modifiers.control)) this.at = (this.at + rows.length - 1) % rows.length;
        else return;
        cx.stop_propagation();
        cx.notify();
      })
      .child(h_flex().items_center()
        .child(div().flex_1().text_size(15).font_semibold().text_color(t.foreground).child("Open project"))
        .child(div().id("pp-esc").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(() => this.close()).child("Esc")))
      .child(
        h_flex().h(36).flex_none().px(10).gap(8).items_center().rounded(9).border_1().border_color(t.accent).bg(t.background)
          .child(svg("mods/workspace-chrome/search.svg").size(15).text_color(t.dim))
          .child(Input.new(this.input).flex_1().h_full().text_size(12.8).text_color(t.foreground)),
      )
      .child(
        v_flex().id("pp-list").h(VISIBLE * ROW).min_h(0).overflow_hidden()
          .children(shown.map((p, i) => {
            const on = start + i === this.at;
            return h_flex()
              .id(`pp-${p.name}`)
              .mx(4)
              .px(10)
              .h(ROW)
              .flex_none()
              .rounded(7)
              .items_center()
              .gap(8)
              .cursor_pointer()
              .when(on, (el) => el.bg(t.hover))
              .hover((s) => s.bg(t.hover))
              .on_click(() => this.go(p))
              .child(svg("mods/workspace-chrome/folder.svg").size(13).flex_none().text_color(t.dim))
              .child(div().flex_1().truncate().text_color(t.foreground).child(p.name));
          })),
      )
      .when(!rows.length, (el) => el.child(div().px(10).text_color(t.dim).child(this.projects.length ? "No match" : "Loading…")));
  }
}
