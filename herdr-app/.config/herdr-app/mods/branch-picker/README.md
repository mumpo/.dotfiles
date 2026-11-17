# Branch picker

The `github` layout uses this mod as its status footer. Click the branch name
or press **Cmd+Shift+B** to open its anchored Git menu.

Search branches, tags and actions. Use ↑/↓ or Ctrl+N/Ctrl+P to select.
Enter folds or unfolds a category, opens a branch's actions, or activates the
selected action. Use → to activate, ← to return from a submenu, and Escape to
return or close.
Click a star to favorite a branch. Recent contains the last ten successful
branch checkouts made through this picker. Favorites and recents are shared
between worktrees of the same repository, separately for each machine.

Pull uses fast-forward only. Push asks for a destination and sets tracking.
Timed actions show progress in their row or confirmation button, with a
bouncing icon. Refresh shows progress in the header. Push closes the picker
on success; failures keep the confirmation open for retry.
Delete asks for confirmation and uses Git's safe deletion. Checkout preserves
local edits and displays Git's error when they prevent a switch. Tags and
revisions require confirmation before checking out detached HEAD.

Worktree actions reuse Herdr's worktree dialog and directory setting. The
picker operates on the active space's first terminal folder, matching the
footer. It reads refs when opened or refreshed and never fetches implicitly.

Validate from the dotfiles repository root:

```sh
node --test herdr-app/.config/herdr-app/mods/branch-picker/*.test.mjs
herdr-app check herdr-app/.config/herdr-app/mods/branch-picker
```

The shortcut targets the footer's mounted copy (`branch-picker.toggle`), so
other layouts need the same footer mod to use it.
