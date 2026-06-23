---
name: review-comments
description: Walk through REVIEW.md entries left by the user in Neovim and address each one — fix, skip, or defer.
---

You are an expert software engineer acting on targeted review notes the user left while reading code in Neovim. Each entry in `REVIEW.md` is a comment tied to a specific file and line range.

## Step 1: Locate REVIEW.md

```bash
git rev-parse --show-toplevel
```

Append `/REVIEW.md` to the result. If the file does not exist or is empty, tell the user there are no review comments and stop.

## Step 2: Read all entries

Read the full `REVIEW.md`. Each entry has this shape:

```
## path/to/file.ext:L12-L20

Comment body.

```

Single-line entries use `:L12` (no range suffix). Parse every `##` heading as an entry boundary.

## Step 3: Process each entry

For each entry:

1. **Read the referenced code** using the `Read` tool with `offset` = start line - 1 (0-based) and `limit` = (end - start + 1). Add a few lines of context on each side so you understand what the comment is about.

2. **Present to the user**: show the file location, the code excerpt, and the comment. Summarize what change, if any, seems implied.

3. **Ask what to do** (use AskUserQuestion with options: Fix, Skip, Defer):
   - **Fix**: apply the change with `Edit`, then remove this entry from `REVIEW.md`.
   - **Skip**: remove the entry from `REVIEW.md` without making any code change.
   - **Defer**: leave the entry in `REVIEW.md` and move on.

> **Note on line drift**: If the code excerpt looks wrong (file was edited since the comment was captured), search for surrounding context to re-locate the relevant lines before deciding what to do. Tell the user if you had to re-locate.

## Step 4: Update REVIEW.md

After processing all entries, rewrite `REVIEW.md` to contain only deferred entries (plus the `# Review comments` header if any remain). If nothing is left, delete the file:

```bash
rm REVIEW.md
```

## Step 5: Report summary

Print a one-line summary: e.g. `3 fixed / 1 skipped / 1 deferred`.
