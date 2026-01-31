return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Show a spinner while a request is in progress
    "franco-ruggeri/codecompanion-spinner.nvim",
  },
  opts = {
    extensions = {
      spinner = {},
    },
    adapters = {
      acp = {
        claude_code = function()
          return require("codecompanion.adapters").extend("claude_code", {
            env = {},
          })
        end,
      },
    },
    strategies = {
      chat = {
        adapter = "claude_code",
        opts = {
          completion_provider = "cmp",
        },
      },
    },
    display = {
      chat = {
        show_settings = true,
        window = {
          layout = "vertical",
          position = "right",
          width = 0.4,
        },
      },
    },
    prompt_library = {
      ["Create PR"] = {
        strategy = "chat",
        description = "Create a draft pull request in GitHub for the current branch.",
        opts = {
          short_name = "create_pr",
          auto_submit = true,
        },
        prompts = {
          {
            role = "system",
            content = [[## Execute list
Execute these steps to create a draft pull request in GitHub for the current branch:
1. Inspect the current branch changes in reference with the `main` branch
2. Synthesize the PR title and description
3. Invoke the `github` MCP tool to open the PR
4. Once created, open the PR URL in the browser

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
- <jira-ticket>: Use the Jira task code, e.g. TU-1234. You can usually find it in the branch name. Otherwise, use NOJIRA-123
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
          ]],
          },
          {
            role = "user",
            content = [[Create the draft pull request for the current branch changes in reference with the `main` branch.]],
          },
        },
      },
    },
  },
  keys = {
    -- { "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion" },
    -- { "<leader>ca", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
    -- {
    --   "<leader>ci",
    --   function()
    --     vim.ui.input({ prompt = "CodeCompanion: " }, function(input)
    --       if input and #input > 0 then
    --         vim.cmd("'<,'>CodeCompanion " .. input)
    --       end
    --     end)
    --   end,
    --   mode = "v",
    --   desc = "Run CodeCompanion on selected code",
    -- },
  },
}
