import { closeOverlay, run, setShared, theme } from "herdr";
import { TextareaState } from "gpui-base";
import { amendDialog } from "./chrome.js";

export class AmendPrompt {
  constructor(props, cx) {
    this.props = props;
    this.handle = cx.focus_handle();
    this.state = TextareaState.new({ value: props.previous.message, rows: 6 });
    this.state.on("change", (_e, cx) => cx.notify());
    this.state.on("submit", () => this.apply());
    this.state.focus();
  }

  close() { closeOverlay(this.props.overlay); }

  apply() {
    const text = this.state.value().trim();
    if (!text || this.submitted) return;
    this.submitted = true;
    const token = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    setShared("gitview.amend", { token, text, where: this.props.where, head: this.props.previous.head });
    this.close();
    run(`gitview.amend:${token}`);
  }

  render() { return amendDialog(theme(), this.state, this.handle, () => this.apply(), () => this.close()); }
}

