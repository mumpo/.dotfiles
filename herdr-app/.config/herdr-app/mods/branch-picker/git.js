import { parseRefs, parseWorktrees } from "./model.js";

export function repository(exec, folder, on = null) {
  const git = async (args, optional = false) => {
    const result = await exec("git", args, { cwd: folder, on, timeout: 120000 });
    if (result.code !== 0 && !optional) throw new Error((result.stderr || result.stdout || `Git exited with ${result.code}`).trim());
    return result;
  };
  const api = {
    git,
    async load() {
      const top = (await git(["rev-parse", "--show-toplevel"])).stdout.trim();
      const common = (await git(["rev-parse", "--path-format=absolute", "--git-common-dir"])).stdout.trim();
      const [refs, head, sha, trees, remotes] = await Promise.all([
        git(["for-each-ref", "--format=%(refname)%09%(upstream)%09%(upstream:track)%09%(upstream:remotename)%09%(upstream:remoteref)", "refs/heads", "refs/remotes", "refs/tags"]),
        git(["symbolic-ref", "--quiet", "HEAD"], true), git(["rev-parse", "--short", "HEAD"], true),
        git(["worktree", "list", "--porcelain", "-z"]), git(["remote"]),
      ]);
      return { top, common, key: JSON.stringify([on, common]), current: head.code === 0 ? head.stdout.trim() : null,
        sha: sha.code === 0 ? sha.stdout.trim() : "unborn", refs: parseRefs(refs.stdout), trees: parseWorktrees(trees.stdout),
        remotes: remotes.stdout.split("\n").filter(Boolean) };
    },
    async validate(name) {
      if (!name || name !== name.trim() || name.startsWith("-")) throw new Error("Enter a valid branch name without surrounding whitespace.");
      await git(["check-ref-format", "--branch", name]);
      // check-ref-format expands @{-n}; this UI takes literal names only.
      if (name.includes("@{")) throw new Error("Enter a literal branch name.");
      return name;
    },
    async commit(revision) {
      if (!revision.trim()) throw new Error("Enter a tag or revision.");
      return (await git(["rev-parse", "--verify", "--end-of-options", `${revision}^{commit}`])).stdout.trim();
    },
    switchLocal(name) { return git(["switch", "--no-guess", "--", name]); },
    async create(name, start = null, tracking = false, checkout = true) {
      await api.validate(name);
      if (tracking) return git(checkout ? ["switch", "--track", "-c", name, start] : ["branch", "--track", "--", name, start]);
      const sha = start ? await api.commit(start) : null;
      return git(["switch", "-c", name, ...(sha ? [sha] : [])]);
    },
    async rename(old, name) { await api.validate(name); return git(["branch", "-m", "--", old, name]); },
    delete(name) { return git(["branch", "-d", "--", name]); },
    pull() { return git(["pull", "--ff-only"]); },
    async push(current, remote, name) {
      await api.validate(name);
      return git(["push", "--porcelain", "--set-upstream", "--", remote, `${current}:refs/heads/${name}`]);
    },
    async detach(revision) { const sha = await api.commit(revision); return git(["switch", "--detach", sha]); },
  };
  return api;
}
