import { describe, expect, mock, test } from "bun:test";
import { githubTheme } from "./github-theme.js";

// Inspect the elements emitted by the real row renderer without opening GPUI.
function element() {
  const data = { children: [] };
  let builder;
  builder = new Proxy(data, {
    get(target, key) {
      if (key === "data") return target;
      if (key === "when") return (condition, apply) => condition ? apply(builder) : builder;
      if (key === "child") return (child) => { target.children.push(child.data ?? child); return builder; };
      if (key === "children") return (children) => { target.children.push(...children.map((child) => child.data ?? child)); return builder; };
      return (...args) => { target[key] = args; return builder; };
    },
  });
  return builder;
}

mock.module("gpui-kit", () => ({ div: element }));
mock.module("gpui-base", () => ({ h_flex: element, v_flex: element, Textarea: {} }));
mock.module("./chrome.js", () => ({ iconButton: element, noteLines: () => "" }));
const { renderRow } = await import("./diffview.js");
const { Scroller } = await import("./scroller.js");

describe("diff scrolling", () => {
  const t = { background: "#0d1117", border: "#333333" };
  const cx = { notify() {}, stop_propagation() {} };
  const render = () => element();

  function setup() {
    const scroll = new Scroller("diff-test");
    scroll.measure(Array(100).fill(18));
    const initial = scroll.view(t, render, { contentWidth: 1400 }).data;
    initial.on_size_change[0]({ width: 400, height: 300 }, cx);
    return scroll;
  }

  test("trackpad moves both axes; Shift+wheel moves horizontally", () => {
    const scroll = setup();
    let view = scroll.view(t, render, { contentWidth: 1400 }).data;
    view.on_scroll_wheel[0]({ delta: { x: -120, y: -36 } }, cx);
    expect(scroll.left).toBe(120);
    expect(scroll.top).toBe(36);
    view = scroll.view(t, render, { contentWidth: 1400 }).data;
    view.on_scroll_wheel[0]({ delta: { x: 0, y: -100 }, modifiers: { shift: true } }, cx);
    expect(scroll.left).toBe(220);
    expect(scroll.top).toBe(36);
    expect(scroll.height).toBe(292); // bottom scrollbar never covers the last line
  });

  test("horizontal thumb drags and clamps; narrower content resets horizontal offset", () => {
    const scroll = setup();
    const view = scroll.view(t, render, { contentWidth: 1400 }).data;
    const track = view.children.at(-1);
    const thumb = track.children[0];
    thumb.on_mouse_down[1]({ position: { x: 20 } }, cx);
    view.on_mouse_move[0]({ position: { x: 100000 } }, cx);
    expect(scroll.left).toBe(1000);
    expect(scroll.top).toBe(0);
    view.on_mouse_up[1]();
    expect(scroll.dragging).toBeNull();
    const narrow = scroll.view(t, render, { contentWidth: 200 }).data;
    expect(scroll.left).toBe(0);
    expect(scroll.height).toBe(300);
    expect(narrow.children.some((child) => child.children?.[0]?.id?.[0] === "diff-test-thumb-x")).toBe(false);
  });

  test("resizing wider clamps the offset and preserves the vertical position", () => {
    const scroll = setup();
    const view = scroll.view(t, render, { contentWidth: 1400 }).data;
    scroll.left = 900;
    scroll.top = 180;
    view.on_size_change[0]({ width: 1000, height: 300 }, cx);
    expect(scroll.left).toBe(400);
    expect(scroll.top).toBe(180);
  });
});

function draw(row, dark, selection = null, options = {}) {
  return renderRow({ row, index: 0 }, {
    t: { background: dark ? "#000000" : "#ffffff", foreground: dark ? "#ffffff" : "#000000", selection: "#264f78" },
    cursor: -1, selection, onDown() {}, onMove() {},
    ...options,
  }).data;
}

function textOf(node) {
  return node.children.flatMap((child) => typeof child === "string" ? [child] : [textOf(child)]).join("").replace(/\u00a0/g, " ");
}

for (const dark of [false, true]) {
  describe(dark ? "GitHub dark" : "GitHub light", () => {
    for (const [kind, role, tint, emph, marker] of [
      ["add", "addition", "@ins", "@ins_emph", "green"],
      ["del", "deletion", "@del", "@del_emph", "red"],
    ]) {
      test(`${kind}: preserves text, line numbers and word ranges with GitHub backgrounds`, () => {
        const row = { k: kind, bg: tint, s: [["▌", marker, tint], [" 12 ", "@gutter", null], ["const ", "#c678dd", tint], ["answer", "#e06c75", emph], [" = 42;", "#dcdfe4", tint]] };
        const result = draw(row, dark);
        const p = githubTheme(dark);
        expect(result.bg).toEqual([p[role]]);
        expect(result.children[0].bg).toEqual([p[`${role}Gutter`]]);
        expect(result.children[1].bg).toBeUndefined();
        expect(result.children[3].bg).toEqual([p[`${role}Word`]]);
        expect(textOf(result)).toBe(` 12 ${kind === "add" ? "+" : "−"} const answer = 42;`);
        const current = draw(row, dark, null, { cursor: 0, focused: true });
        expect(current.bg).toEqual([p[role]]);
        expect(current.children.length).toBe(result.children.length);
        expect(current.children[0].font_semibold).toEqual([]);
        expect(row.s[0][0]).toBe("▌"); // presentation leaves the engine data intact
        // Selection takes precedence over both the line and word backgrounds.
        const selected = draw(row, dark, [0, 0]);
        expect(selected.bg).toEqual(["#264f78"]);
        expect(selected.children[3].bg).toBeUndefined();
      });
    }

    test("maps both engine palettes while switching appearance", () => {
      for (const [keyword, string, comment] of [["#c678dd", "#98c379", "#5c6370"], ["#a71d5d", "#183691", "#969896"]]) {
        const result = draw({ k: "ctx", s: [["import", keyword, null], [' "x";', string, null], [" // note", comment, null]] }, dark);
        const syntax = githubTheme(dark).syntax;
        expect(result.children[0].text_color).toEqual([syntax.keyword]);
        expect(result.children[1].text_color).toEqual([syntax.string]);
        expect(result.children[2].text_color).toEqual([syntax.comment]);
        expect(textOf(result)).toBe('import "x"; // note');
      }
    });

    test("JSON keys and literals use GitHub constant blue, strings retain their color", () => {
      for (const [key, string, literal, plain] of [["#c678dd", "#98c379", "#e5c07b", "#dcdfe4"], ["#183691", "#183691", "#0086b3", "#323232"]]) {
        const row = { k: "ctx", s: [['"noEmit"', key], [": ", plain], ["true", literal], [', "path"', plain], [": ", plain], ['"apps/**/*.ts"', string]] };
        const result = draw(row, dark, null, { path: "tsconfig.json" });
        const p = githubTheme(dark);
        expect(result.children[0].text_color).toEqual([p.syntax.constant]);
        expect(result.children[2].text_color).toEqual([p.syntax.constant]);
        expect(result.children[5].text_color).toEqual([p.syntax.string]);
        expect(textOf(result)).toBe('"noEmit": true, "path": "apps/**/*.ts"');
      }
    });
  });
}
