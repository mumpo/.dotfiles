// Pure data helpers; no host APIs, so these also run in the repository tests.
export function parseRefs(text) {
  return text.split("\n").filter(Boolean).map(line => {
    const [ref, upstream, track, remote, remoteRef] = line.split("\t");
    const kind = ref.startsWith("refs/heads/") ? "local" : ref.startsWith("refs/remotes/") ? "remote" : "tag";
    const prefix = kind === "local" ? "refs/heads/" : kind === "remote" ? "refs/remotes/" : "refs/tags/";
    return { ref, name: ref.slice(prefix.length), kind, upstream: upstream || "", remote: remote || "", remoteRef: remoteRef || "",
      ahead: Number(track?.match(/ahead (\d+)/)?.[1] || 0), behind: Number(track?.match(/behind (\d+)/)?.[1] || 0) };
  }).filter(r => !(r.kind === "remote" && r.name.endsWith("/HEAD")));
}

export function parseWorktrees(text) {
  const trees = [];
  let tree;
  // -z keeps spaces, Unicode and quoted-looking paths intact.
  for (const field of text.split("\0")) {
    if (field.startsWith("worktree ")) { tree = { path: field.slice(9), ref: null }; trees.push(tree); }
    else if (field.startsWith("branch ") && tree) tree.ref = field.slice(7);
  }
  return trees;
}

export function score(query, name) {
  if (!query.trim()) return 0;
  const text = name.toLowerCase(), q = query.trim().toLowerCase();
  let at = 0, total = 0, run = 0;
  for (let i = 0; i < text.length && at < q.length; i++) {
    if (text[i] !== q[at]) { run = 0; continue; }
    total += 1 + ++run * 2 + (i === 0 || "/-_ ".includes(text[i - 1]) ? 5 : 0);
    at++;
  }
  return at === q.length ? total - name.length / 1000 : null;
}

export function ordered(refs, query, favorites = []) {
  return refs.map(r => ({ r, score: score(query, r.name) })).filter(x => x.score !== null)
    .sort((a, b) => Number(favorites.includes(b.r.ref)) - Number(favorites.includes(a.r.ref)) || b.score - a.score || a.r.name.localeCompare(b.r.name))
    .map(x => x.r);
}

export function recentRefs(recent, refs) {
  return recent.map(ref => refs.find(r => r.ref === ref)).filter(Boolean);
}

export function remember(recent, ref) { return [ref, ...recent.filter(r => r !== ref)].slice(0, 10); }

export function trackingName(ref, remotes) {
  const remote = [...remotes].sort((a, b) => b.length - a.length).find(r => ref.name.startsWith(`${r}/`));
  if (!remote) throw new Error("The remote for this branch no longer exists. Refresh and try again.");
  return ref.name.slice(remote.length + 1);
}
