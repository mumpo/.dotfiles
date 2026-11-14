// Keyboard focus and the app's pane selection must move together, so only
// one panel has an accent outline. Used by this workspace sidebar viewer.
import { focused, nextCommand, props, run, closeOverlay } from "herdr";

export class PanelFocus {
  constructor(cx, onCommand) {
    this.handle = cx.focus_handle();
    this.overlayId = props()?.overlay;
    this.overlay = Boolean(this.overlayId);
    this.childFocused = false;
    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "focus") {
          this.viaApp = true;
          if (!this.childFocused) this.handle.focus();
          cx.notify();
        } else onCommand?.(command, cx);
      }
    });
  }

  dismiss() {
    if (this.overlayId) { closeOverlay(this.overlayId); return; }
    const pane = focused()?.pane;
    if (pane) run("pane.focus", { pane });
    else run("pane.go", { direction: "left" });
    run("layout.hide", { id: "panel" });
  }

  request(cx) {
    if (this.handle.is_focused() || this.viaApp && this.childFocused) return;
    if (this.overlay) { this.handle.focus(); cx.notify(); return; }
    this.viaApp = false;
    // Start from the active terminal, then move to the sidebar at its right.
    const pane = focused()?.pane;
    if (pane) run("pane.focus", { pane });
    run("pane.go", { direction: "right" });
    cx.spawn(async (cx) => {
      // A split can sit between the active terminal and the sidebar.
      for (let i = 0; i < 3 && !this.viaApp; i++) {
        await cx.sleep(150);
        if (!this.viaApp) run("pane.go", { direction: "right" });
      }
    });
  }

  frame(element, t) {
    const hasFocus = this.handle.is_focused() || this.childFocused;
    if (!hasFocus) this.viaApp = false;
    return element.track_focus(this.handle)
      .on_mouse_down("left", (_event, cx) => this.request(cx))
      .rounded(10).overflow_hidden().border_1()
      .border_color(hasFocus ? t.accent : t.border);
  }
}
