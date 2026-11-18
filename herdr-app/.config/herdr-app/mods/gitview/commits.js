import { exec, setShared, shared } from "herdr";

export function takeAmend(token) {
  const pending = shared("gitview.amend");
  if (!pending || pending.token !== token) return null;
  setShared("gitview.amend", null);
  return pending;
}

async function git(where, args) {
  const result = await exec("git", args, { cwd: where.root, on: where.on, timeout: 30000 });
  if (result.code !== 0) throw new Error((result.stderr || result.stdout).trim() || `git ${args[0]} failed`);
  return result.stdout;
}

export async function lastCommit(where) {
  const output = await git(where, ["--no-optional-locks", "log", "-1", "--format=%H%x00%B"]);
  const separator = output.indexOf("\0");
  if (separator < 0) throw new Error("No previous commit to amend");
  return { head: output.slice(0, separator), message: output.slice(separator + 1).trimEnd() };
}

// Explicit choices never fall back from staged changes to all changes.
// Amend uses the index, so unstaged and untracked work stays out of it.
export async function writeCommit(where, text, choice, head = null) {
  if (choice === "amend") {
    const current = (await git(where, ["--no-optional-locks", "rev-parse", "HEAD"])).trim();
    if (current !== head) throw new Error("The last commit changed. Open Amend again to review its message.");
  }
  const conflicts = await git(where, ["--no-optional-locks", "diff", "--name-only", "--diff-filter=U"]);
  if (conflicts.trim()) throw new Error("Resolve conflicts before committing");
  if (choice === "all") await git(where, ["add", "-A"]);
  return { summary: (await git(where, ["commit", ...(choice === "amend" ? ["--amend"] : []), "-m", text])).trim() };
}
