// The sidebar viewers supply the key descriptions for the current view.
import { View, div } from "gpui-kit";
import { h_flex, v_flex } from "gpui-base";
import { props, theme, closeOverlay, nextCommand } from "herdr";

export default class SidebarKeys extends View {
  init(_props, cx) {
    this.given = props() ?? {};
    this.handle = cx.focus_handle();
    this.handle.focus();
    cx.spawn(async () => {
      for (;;) { const command = await nextCommand(); if (command.startsWith("key:")) this.key(command.slice(4)); }
    });
  }
  key(key) {
    if (key !== "escape" && key !== "?") return false;
    closeOverlay(this.given.overlay);
    return true;
  }
  render() {
    const t = theme();
    const cap = key => div().h(20).min_w(20).px(5).flex_none().flex().items_center().justify_center()
      .rounded(4).border_1().border_color(t.border).bg(t.raised).text_size(11).text_color(t.foreground).child(key);
    return v_flex().id("sidebar-keys").size_full().p(16).gap(12).bg(t.popover).text_color(t.foreground)
      .track_focus(this.handle).on_key_down((e, cx) => {
        if (this.key(e.modifiers?.shift && e.key === "/" ? "?" : e.key)) cx.stop_propagation();
      })
      .child(h_flex().gap(8).items_center().child(div().flex_1().text_size(15).font_semibold().child(this.given.title ?? "Keys"))
        .child(div().id("keys-close").cursor_pointer().on_click(() => this.key("escape")).child(cap("Esc"))))
      .children((this.given.keys ?? []).map(entry => h_flex().h(24).gap(12).items_center()
        .child(h_flex().w(104).flex_none().gap(4).children(entry.caps.map(cap)))
        .child(div().text_size(12).text_color(t.muted).child(entry.label))));
  }
}
