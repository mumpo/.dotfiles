// A read-only Markdown viewer for the side panel: the Markdown files of the
// focused pane's folder (git's, else found 3 deep), one click to read it
// formatted, following the file while an agent writes it. A pane on another
// machine lists and reads that machine's files. Links: http(s) and mailto open
// in the browser, a link to another .md opens here.
import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex, TextView } from "gpui-base";
import { spaces, panes, focused, exec, readTextFile, watchFolder, appHome, home, theme } from "herdr";

function location() {
  const space = spaces().find(s => s.active), f = focused();
  const pane = f?.pane ? panes().find(p => p.pane === f.pane) : null;
  const on = f?.pane === null ? (f.terminal?.includes("/") ? f.terminal.split("/")[0] : null) : space?.machine ?? null;
  return { cwd: pane?.cwd || f?.cwd || space?.folder || null, on };
}

const LIST = `{ git ls-files --cached --others --exclude-standard -- '*.md' '*.markdown' '*.mdx' 2>/dev/null; } | grep . ||
  find . -maxdepth 3 -name node_modules -prune -o -type f \\( -name '*.md' -o -name '*.markdown' -o -name '*.mdx' \\) -print | sed 's|^\\./||'`;
const SORT = `sort | head -300`;

// Paths into a tree of folders (a chain of single-child folders is one row,
// `a/b/c`) and files, folders first; flattened to the rows that are showing.
function tree(files, collapsed) {
  const root = { dirs: new Map(), files: [] };
  for (const f of files) {
    const parts = f.rel.split("/"), name = parts.pop();
    let node = root;
    for (const part of parts) {
      if (!node.dirs.has(part)) node.dirs.set(part, { dirs: new Map(), files: [] });
      node = node.dirs.get(part);
    }
    node.files.push({ ...f, name });
  }
  const rows = [];
  const walk = (node, depth, prefix) => {
    for (const [name, dir] of [...node.dirs].sort(([a], [b]) => a.localeCompare(b))) {
      let label = name, cur = dir;
      while (cur.files.length === 0 && cur.dirs.size === 1) {
        const [[n, d]] = cur.dirs;
        label += "/" + n; cur = d;
      }
      const key = `${prefix}${label}/`, open = !collapsed.has(key);
      rows.push({ dir: true, label, key, depth, open });
      if (open) walk(cur, depth + 1, key);
    }
    for (const f of node.files.sort((a, b) => a.name.localeCompare(b.name))) rows.push({ file: f, depth });
  };
  walk(root, 0, "");
  return rows;
}

// YAML front matter at the top of the file -> its fields (flat keys; a value is
// a string or a list; anything nested stays text) and the Markdown after it.
function frontmatter(text) {
  const m = /^---[ \t]*\r?\n([\s\S]*?)\r?\n(?:---|\.\.\.)[ \t]*(?:\r?\n|$)/.exec(text);
  if (!m) return null;
  const unquote = (v) => v.trim().replace(/^(["'])([\s\S]*)\1$/, "$2");
  const fields = [];
  for (const line of m[1].split(/\r?\n/)) {
    const kv = /^([A-Za-z0-9_.-]+):[ \t]*(.*)$/.exec(line);
    if (kv) {
      const v = kv[2].trim();
      if (/^\[.*\]$/.test(v)) fields.push({ key: kv[1], items: v.slice(1, -1).split(",").map(unquote).filter(Boolean) });
      else if (/^[|>][-+]?$/.test(v) || v === "") fields.push({ key: kv[1], value: "", block: true });
      else fields.push({ key: kv[1], value: unquote(v) });
    } else if (fields.length && line.trim()) {
      const last = fields[fields.length - 1], item = /^\s*-\s+(.*)$/.exec(line);
      if (item) { last.items = [...(last.items ?? []), unquote(item[1])]; delete last.block; }
      else last.value = (last.value ? last.value + " " : "") + line.trim();
    }
  }
  return { fields: fields.filter((f) => f.items?.length || f.value), body: text.slice(m[0].length) };
}

const dirname = (p) => p.replace(/\/[^/]*$/, "") || "/";
const basename = (p) => p.replace(/^.*\//, "");
function resolve(base, rel) {
  const out = rel.startsWith("/") ? [] : base.split("/");
  for (const part of rel.split("/")) {
    if (part === "..") out.pop();
    else if (part && part !== ".") out.push(part);
  }
  return out.join("/") || "/";
}

export default class Markdown extends View {
  // Each space has its own context: its folder's list, the file it shows, the
  // folders it collapsed. The open file is remembered across restarts.
  init(_props, cx) {
    this.saved = new Map();
    this.remembered = JSON.parse(localStorage.getItem("files") ?? "{}");
    this.sid = undefined;
    this.swap();
    this.load(cx);
    this.watchInbox(cx);
    cx.timer.every(500, (cx) => { this.swap(); this.load(cx); });
    cx.timer.every(2000, (cx) => this.tick(cx));
  }

  // Pure field swap, safe in render: this.file, files, ... are the active space's.
  swap() {
    const id = spaces().find((s) => s.active)?.id ?? null;
    if (id === this.sid) return;
    if (this.sid !== undefined) this.saved.set(this.sid, { file: this.file, files: this.files, loc: this.loc, collapsed: this.collapsed, error: this.error });
    this.sid = id;
    const st = this.saved.get(id);
    if (st) { Object.assign(this, st); this.pendingLoad = st.files === null || st.file?.text === null; return; }
    const r = this.remembered[id];
    this.loc = location();
    this.files = null; // null: looking
    this.file = r ? { path: r.path, on: r.on ?? null, text: null } : null; // { path, on, text }
    this.error = null;
    this.collapsed = new Set();
    this.pendingLoad = true;
  }

  // The work a swap to a new space needs (it can't run in render).
  load(cx) {
    if (!this.pendingLoad) return;
    this.pendingLoad = false;
    this.list(cx);
    if (this.file) this.read(cx, false);
  }

  remember() {
    if (this.sid == null) return;
    if (this.file) this.remembered[this.sid] = { path: this.file.path, on: this.file.on };
    else delete this.remembered[this.sid];
    try { localStorage.setItem("files", JSON.stringify(this.remembered)); } catch {}
  }

  // `md-open` leaves a path in data/markdown-open/: open the newest, drop all.
  async inbox(cx) {
    const dir = `${appHome()}/data/markdown-open`;
    const script = 'mkdir -p "$1"; f=$(ls -t "$1"/*.path 2>/dev/null | head -1); [ -n "$f" ] && cat "$f"; rm -f "$1"/*.path; :';
    const r = await exec("sh", ["-c", script, "markdown", dir]);
    const path = r.stdout.trim();
    if (path) { this.open(path, null, cx); cx.notify(); }
    return dir;
  }

  watchInbox(cx) {
    cx.spawn(async (cx) => {
      try {
        const dir = await this.inbox(cx);
        for (;;) { await watchFolder(dir); await this.inbox(cx); }
      } catch { this.watchFailed = true; }
    });
  }

  tick(cx) {
    if (this.watchFailed) this.inbox(cx).catch(() => {});
    const loc = location();
    if (!this.file && (loc.cwd !== this.loc.cwd || loc.on !== this.loc.on)) {
      this.loc = loc;
      this.list(cx);
    } else if (this.file) this.read(cx, true);
  }

  list(cx) {
    const { cwd, on } = this.loc;
    this.files = null; this.error = null; cx.notify();
    if (!cwd) { this.files = []; return; }
    cx.spawn(async (cx) => {
      try {
        const r = await exec("sh", ["-c", `( ${LIST} ) | ${SORT}`], { cwd, on });
        if (this.loc.cwd === cwd && this.loc.on === on) this.files = r.stdout.split("\n").filter(Boolean).map((rel) => ({ rel, path: resolve(cwd, rel) }));
      } catch (e) { this.files = []; this.error = String(e?.message ?? e); }
      cx.notify();
    });
  }

  open(path, on, cx) {
    this.file = { path, on, text: null };
    this.remember();
    this.read(cx, false);
  }

  read(cx, quiet) {
    const f = this.file;
    if (!f || this.reading) return;
    this.reading = true;
    cx.spawn(async (cx) => {
      try {
        const text = await readTextFile(f.path, { on: f.on });
        if (this.file === f && (text ?? "") !== f.text) { f.text = text ?? ""; f.missing = text === null; cx.notify(); }
      } catch (e) { if (!quiet) this.error = String(e?.message ?? e); }
      this.reading = false;
    });
  }

  back(cx) { this.file = null; this.remember(); this.loc = location(); this.list(cx); }

  link(url, cx) {
    const f = this.file;
    if (/^(https?:|mailto:)/.test(url)) exec("open", [url]).catch(() => {});
    else if (f && /\.(md|markdown|mdx)(#.*)?$/i.test(url)) this.open(resolve(dirname(f.path), decodeURI(url.replace(/#.*$/, ""))), f.on, cx);
  }

  pretty(path, on) {
    const h = home();
    const p = !on && path.startsWith(h + "/") ? "~" + path.slice(h.length) : path;
    return on ? `${on}: ${p}` : p;
  }

  // The front matter as a card (title, description, then the other fields), a
  // separator, then the formatted Markdown.
  document(f, t, cx) {
    const fm = frontmatter(f.text);
    const md = (text) => TextView.markdown(`md-${f.path}`, text).selectable(true).on_link_click((url, cx) => this.link(url, cx));
    if (!fm || fm.fields.length === 0) return [md(fm ? fm.body : f.text)];
    const title = fm.fields.find((x) => x.key === "title" || x.key === "name");
    const description = fm.fields.find((x) => x.key === "description" && x.value);
    const rest = fm.fields.filter((x) => x !== title && x !== description);
    const chip = (label) => div().px(7).py(1).rounded(5).text_size(11.5).bg(t.raised).border_1().border_color(t.border).text_color(t.muted).child(label);
    const card = v_flex().gap(8).p(12).rounded(8).bg(t.raised).border_1().border_color(t.border)
      .when(Boolean(title?.value), (e) => e.child(div().text_size(16).font_semibold().text_color(t.foreground).child(title.value)))
      .when(Boolean(description), (e) => e.child(div().text_size(12.5).text_color(t.muted).child(description.value)))
      .when(rest.length > 0, (e) => e.child(v_flex().gap(5).pt(title || description ? 4 : 0)
        .children(rest.map((x) => h_flex().gap(10).items_start()
          .child(div().w(84).flex_none().text_size(11).text_color(t.dim).pt(2).truncate().child(x.key))
          .child(x.items
            ? h_flex().flex_1().min_w(0).flex_wrap().gap(5).children(x.items.map(chip))
            : div().flex_1().min_w(0).text_size(12.5).text_color(t.foreground).child(x.value))))));
    const out = [card, div().h(1).flex_none().my(14).bg(t.border)];
    if (fm.body.trim()) out.push(md(fm.body));
    return out;
  }

  render(cx) {
    this.swap();
    const t = theme();
    const f = this.file;
    const iconButton = (id, label, onClick) => div().id(id).px(7).py(2).rounded(5).text_size(12).text_color(t.dim).cursor_pointer()
      .hover((s) => s.bg(t.hover).text_color(t.foreground)).on_click(onClick).child(label);
    const header = h_flex().h(42).flex_none().px(10).gap(6).items_center().border_b(1).border_color(t.border)
      .when(Boolean(f), (e) => e.child(iconButton("md-back", "‹", (_e, cx) => this.back(cx))))
      .child(v_flex().flex_1().min_w(0)
        .child(div().text_size(13).font_semibold().truncate().child(f ? basename(f.path) : "Markdown"))
        .child(div().text_size(11).text_color(t.dim).truncate().child(this.pretty(f ? dirname(f.path) : this.loc.cwd ?? "", f ? f.on : this.loc.on))))
      .child(iconButton("md-reload", "↻", (_e, cx) => (f ? this.read(cx, false) : this.list(cx))));

    let body;
    if (f) {
      body = f.text === null
        ? div().p(16).text_size(12).text_color(this.error ? t.ansi1 : t.dim).child(this.error ?? "Reading…")
        : f.missing
          ? div().p(16).text_size(12).text_color(t.ansi1).child("The file is gone.")
          : v_flex().id("md-doc").flex_1().min_h(0).overflow_y_scroll().px(16).py(12).text_size(14).font_family("Inter Variable").text_color(t.foreground)
            .children(this.document(f, t, cx));
    } else if (this.files === null) {
      body = div().p(16).text_size(12).text_color(t.dim).child("Looking for Markdown…");
    } else if (this.files.length === 0) {
      body = div().p(16).text_size(12).text_color(this.error ? t.ansi1 : t.dim).child(this.error ?? "No Markdown files in this folder.");
    } else {
      body = v_flex().id("md-list").flex_1().min_h(0).overflow_y_scroll().py(4).children(tree(this.files, this.collapsed).map((r, i) => {
        const row = h_flex().id(`md-row-${i}`).h(26).flex_none().pr(12).pl(10 + r.depth * 14).gap(6).items_center().cursor_pointer().hover((s) => s.bg(t.hover));
        if (r.dir) {
          return row.on_click((_e, cx) => { this.collapsed.has(r.key) ? this.collapsed.delete(r.key) : this.collapsed.add(r.key); cx.notify(); })
            .child(svg(`mods/files/chevron-${r.open ? "down" : "right"}.svg`).size(11).flex_none().text_color(t.dim))
            .child(svg("mods/files/folder.svg").size(14).flex_none().text_color(t.muted))
            .child(div().text_size(13).min_w(0).truncate().text_color(t.muted).child(r.label));
        }
        return row.on_click((_e, cx) => this.open(r.file.path, this.loc.on, cx))
          .child(div().w(11).flex_none())
          .child(svg("mods/files/file.svg").size(14).flex_none().text_color(t.dim))
          .child(div().text_size(13).min_w(0).truncate().child(r.file.name));
      }));
    }
    return v_flex().size_full().min_w(0).bg(t.surface).text_color(t.foreground).child(header).child(body);
  }
}
