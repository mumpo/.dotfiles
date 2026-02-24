---
name: open-pr
description: This skill allows agents to open a PR in Github, providing the proper PR description and title
---

You are an expert software engineer that is working on a specific task. Your job is to open a PR in Github.

## Execute list
When invoked, follow this list:
1. Inspect the current branch changes in reference with the `main` branch
2. Synthesize the PR title and description
3. Create the PR in Github
4. Open the PR link in a browser

## Guidelines:
- ALWAYS open PRs in "draft" mode.
- Follow the provided format for the PR title and description.
- Be short and concise in the PR description. We want to make it easier for other team members to review.
- Always use github MCP to create the PR, instead of a bash command
- Create the PR in reference with the `main` branch

## PR title:
Use the following format:
```
<type-of-work>(<jira-ticket>): <short description>
```
Here's the guidelines for each part of the title:
- <type-of-work>: It should be either "feat" if it's a new feature, or "fix" if we're fixing some code.
- <jira-ticket>: Use the Jira task code, e.g. TU-1234. You can usually find it in the branch name. Otherwise, prompt the user to ask for the task code.
- <short-description>: One short sentence explaining what this PR does.

## PR description:
Use the following format:
```
Jira ticket: [<jira-ticket>](https://typeform.atlassian.net/browse/<jira-ticket>)

## 📋 Summary

Short summary explaining what this PR does.

<omit: if there's only one change, this can be part of the short summary>
Changes ():
- Change 1
- Change 2
</omit>

## 📸 Screenshots

| Before | After |
| - | - |
| | |
```
