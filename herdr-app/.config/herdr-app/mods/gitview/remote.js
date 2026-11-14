import { exec, notify } from "herdr";

// keyName deliberately leaves control chords to the app. Opt in only to
// Ctrl+N here, keeping Cmd+N and modified variants available to Herdr.
export function notesKey(e) {
  const m = e.modifiers ?? {};
  return m.control && !m.platform && !m.alt && !m.shift && e.key.toLowerCase() === "n" ? "ctrl-n" : null;
}

export function remoteOperation(view, operation, cx) {
  if (operation !== "pull" && operation !== "push") return;
  const where = view.work?.where;
  if (!where?.root) return view.flash.set("No repository loaded");
  if (view.remoteOperation || view.commitRunning()) return;
  view.remoteOperation = operation;
  view.loads.run(cx, operation, async (cx) => {
    try {
      const result = await exec("git", operation === "pull" ? ["pull", "--ff-only"] : ["push"], {
        cwd: where.root, on: where.on, timeout: 30000,
      });
      const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
      if (result.code !== 0) throw new Error(output || `git ${operation} exited with code ${result.code}`);
      view.flash.set(operation === "pull" ? "Pulled" : "Pushed");
      notify({ title: `Git ${operation}`, body: output.slice(0, 2000) || "Done", level: "info" });
    } catch (error) {
      const body = String(error?.message ?? error);
      view.flash.set(`git ${operation} failed`);
      notify({ title: `Git ${operation} failed`, body: body.slice(0, 2000), level: "error" });
    } finally {
      view.remoteOperation = null;
      view.refresh(cx);
    }
  });
}
