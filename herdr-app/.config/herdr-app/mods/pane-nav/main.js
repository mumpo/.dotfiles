// ctrl-h/j/k/l: hand the key to nvim when it is in front of the focused
// terminal (it moves between its own splits and crosses to herdr at an edge),
// else move pane focus. Lives in a zero-size layout block so key commands
// (`pane-nav.left`, ...) reach it without opening an overlay.

import { View, div } from "gpui-kit";
import { exec, focused, nextCommand, run } from "herdr";

const KEYS = { left: "ctrl+h", down: "ctrl+j", up: "ctrl+k", right: "ctrl+l" };
const VIM = /^g?(view|l?n?vim?x?)(diff)?$/;

async function go(direction) {
  const terminal = focused()?.terminal;
  try {
    const info = terminal ? JSON.parse((await exec("hc", ["get", terminal])).stdout) : null;
    if (terminal && VIM.test((info?.foreground?.name ?? "").toLowerCase())) {
      await exec("hc", ["keys", terminal, KEYS[direction]]);
      return;
    }
  } catch (e) {}
  run("pane.go", { direction });
}

export default class PaneNav extends View {
  init(_props, cx) {
    cx.spawn(async () => {
      for (;;) {
        const c = await nextCommand();
        if (KEYS[c]) go(c);
      }
    });
  }

  render() {
    return div();
  }
}
