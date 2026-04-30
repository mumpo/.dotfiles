return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      provider = {
        enabled = "tmux",
        tmux = {
          options = "-hf -l 90", -- Full-height horizontal split (takes precedence over existing vertical splits)
        },
      },
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    vim.keymap.set({ "n", "x" }, "<leader>ci", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Ask opencode inline" })

    vim.keymap.set({ "n", "x" }, "<leader>cs", function()
      require("opencode").command "session.select"
    end, { desc = "Select opencode session" })

    -- vim.keymap.set({ "n", "t" }, "<leader>cc", function()
    --   require("opencode").toggle()
    -- end, { desc = "Toggle opencode" })
    --
    -- vim.keymap.set({ "n", "x" }, "<leader>ct", function()
    --   return require("opencode").operator "@this "
    -- end, { desc = "Add this to opencode", expr = true })
    --
    -- vim.keymap.set("n", "<leader>cb", function()
    --   return require("opencode").prompt "@buffer "
    -- end, { desc = "Add buffer to opencode", expr = true })
  end,
}
