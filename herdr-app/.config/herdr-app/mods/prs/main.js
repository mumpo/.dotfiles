// Pull requests: my open pull requests (via the gh CLI). Open with the `mod.open:prs` command.
import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, theme, closeOverlay, props } from "herdr";

const QUERY = `query($q:String!){search(query:$q,type:ISSUE,first:50){nodes{... on PullRequest{
  number title url isDraft updatedAt reviewDecision repository{nameWithOwner}
  commits(last:1){nodes{commit{statusCheckRollup{state}}}}}}}}`;

function ago(iso) {
  const m = Math.max(0, (Date.now() - Date.parse(iso)) / 60000);
  if (m < 60) return `${Math.floor(m)}m`;
  if (m < 1440) return `${Math.floor(m / 60)}h`;
  return `${Math.floor(m / 1440)}d`;
}

export default class Prs extends View {
  init(_p, cx) {
    this.prs = []; this.error = null; this.loading = false; this.fetched = null;
    this.refresh(cx);
    cx.timer.every(120000, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true; cx.notify();
    cx.spawn(async (cx) => {
      try {
        // Interactive login shell: the GUI app doesn't inherit GH_TOKEN, your zshrc sets it.
        const r = await exec("zsh", ["-lic", 'exec gh "$@"', "gh", "api", "graphql", "-f", `query=${QUERY}`, "-f", "q=is:pr is:open archived:false author:@me sort:updated-desc"], { timeout: 30000 });
        const json = r.stdout.slice(r.stdout.indexOf("{"));
        if (r.code !== 0 || !json) throw new Error((r.stderr || r.stdout).trim().slice(0, 200) || "gh failed");
        const nodes = JSON.parse(json).data.search.nodes.filter((n) => n && n.url);
        this.prs = nodes.map((n) => ({
          repo: n.repository.nameWithOwner, number: n.number, title: n.title, url: n.url,
          draft: n.isDraft, review: n.reviewDecision, updated: n.updatedAt,
          ci: n.commits.nodes[0]?.commit.statusCheckRollup?.state ?? null,
        }));
        this.error = null; this.fetched = new Date();
      } catch (e) { this.error = String(e.message ?? e); }
      finally { this.loading = false; cx.notify(); }
    });
  }

  render(cx) {
    const t = theme();
    const ciColor = { SUCCESS: t.ansi2, FAILURE: t.ansi1, ERROR: t.ansi1, PENDING: t.ansi3, EXPECTED: t.ansi3 };
    const reviewLabel = { APPROVED: ["approved", t.ansi2], CHANGES_REQUESTED: ["changes requested", t.ansi1], REVIEW_REQUIRED: ["needs review", t.muted] };
    const rows = this.prs.map((p, i) => {
      const [rl, rc] = reviewLabel[p.review] ?? ["", t.dim];
      return h_flex().id(`pr-${i}`).gap(10).px(12).py(7).items_center().cursor_pointer()
        .hover((s) => s.bg(t.hover))
        .on_click(() => { exec("open", [p.url]); props()?.overlay && closeOverlay(props()?.overlay); })
        .child(div().w(8).h(8).rounded(4).flex_none().bg(ciColor[p.ci] ?? t.dim))
        .child(v_flex().flex_1().min_w(0).gap(2)
          .child(div().text_size(13).text_color(t.foreground).whitespace_nowrap().text_ellipsis().child(`${p.draft ? "[draft] " : ""}${p.title}`))
          .child(div().text_size(11).text_color(t.dim).child(`${p.repo}#${p.number}`)))
        .child(div().text_size(11).text_color(rc).flex_none().child(rl))
        .child(div().text_size(11).text_color(t.dim).w(28).flex_none().child(ago(p.updated)));
    });
    const status = this.error ? this.error : this.loading && !this.fetched ? "Loading…"
      : `${this.prs.length} open · ${this.fetched ? this.fetched.toLocaleTimeString() : ""}`;
    return v_flex().size_full().bg(props()?.overlay ? t.popover : t.surface).text_color(t.foreground)
      .child(h_flex().px(12).py(8).gap(8).items_center()
        .child(div().text_size(13).flex_1().child("Pull requests"))
        .child(div().text_size(11).text_color(this.error ? t.ansi1 : t.dim).child(status))
        .child(div().id("prs-refresh").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer()
          .hover((s) => s.bg(t.hover)).on_click((_e, cx) => this.refresh(cx)).child("↻"))
        .when(Boolean(props()?.overlay), (e) => e.child(div().id("prs-esc").px(6).py(2).rounded(5).text_size(11).text_color(t.dim).cursor_pointer()
          .hover((s) => s.bg(t.hover)).on_click(() => props()?.overlay && closeOverlay(props()?.overlay)).child("Esc"))))
      .child(v_flex().flex_1().min_h(0).overflow_y_scroll().children(rows));
  }
}
