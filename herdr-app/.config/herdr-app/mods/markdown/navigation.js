// The same key descriptions feed the footer and its help card.
import { div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { openOverlay } from "herdr";

export function keyName(e) {
  const m = e.modifiers ?? {};
  if (m.platform || m.control || m.alt) return null;
  if (m.shift && e.key === "/") return "?";
  return m.shift && /^[a-z]$/.test(e.key) ? e.key.toUpperCase() : e.key;
}

const cap = (t, key) => div().h(16).min_w(16).px(4).flex_none().flex().items_center().justify_center()
  .rounded(4).border_1().border_color(t.border).bg(t.raised).text_size(10.5).text_color(t.foreground).child(key);
export function keymap(preview) {
  return preview
    ? [{ caps: ["Esc"], label: "back to files" }, { caps: ["?"], label: "all keys" }]
    : [{ caps: ["j", "↓"], label: "next row" }, { caps: ["k", "↑"], label: "previous row" },
       { caps: ["Enter"], label: "open file / toggle folder" }, { caps: ["Esc"], label: "close sidebar" },
       { caps: ["?"], label: "all keys" }];
}
export function showKeys(title, preview) {
  openOverlay({ mod: "sidebar-keys", kind: "dialog", width: 480, height: 240,
    props: { title: `${title}: keys`, keys: keymap(preview) } });
}
export function footer(t, title, preview) {
  const chip = (caps, label) => h_flex().gap(4).items_center().flex_none()
    .children(caps.map(key => cap(t, key))).child(div().text_size(11).text_color(t.dim).child(label));
  return h_flex().h(28).flex_none().px(12).gap(10).items_center().border_t(1).border_color(t.border)
    .child(h_flex().flex_1().min_w(0).gap(12).overflow_hidden()
      .child(preview ? chip(["Esc"], "back") : chip(["j", "k"], "move"))
      .when(!preview, el => el.child(chip(["Enter"], "open"))))
    .child(div().id("sidebar-keys-button").flex_none().cursor_pointer().rounded(4).hover(s => s.bg(t.hover))
      .tooltip("All keys (?)").on_mouse_down("left", (_e, cx) => cx.stop_propagation())
      .on_click((_e, cx) => { cx.stop_propagation(); showKeys(title, preview); }).child(cap(t, "?")));
}
