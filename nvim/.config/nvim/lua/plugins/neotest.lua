return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "marilari88/neotest-vitest",
    "nvim-neotest/neotest-jest",
    "nvim-neotest/neotest-go",
  },
  keys = function()
    local neotest = require "neotest"
    return {
      {
        "<leader>tr",
        function()
          neotest.run.run()
        end,
        desc = "Run nearest test",
      },
      {
        "<leader>tf",
        function()
          neotest.run.run(vim.fn.expand "%")
        end,
        desc = "Run tests in file",
      },
      {
        "<leader>ts",
        function()
          neotest.summary.toggle()
        end,
        desc = "Toggle test summary",
      },
      {
        "<leader>to",
        function()
          neotest.output.open()
        end,
        desc = "Show test output",
      },
    }
  end,
  config = function()
    -- testify makes heavy use of tabs and newlines in the error messages
    -- which reduces the readability of the generated virtual text.
    local neotest_ns = vim.api.nvim_create_namespace "neotest"
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          return message
        end,
      },
    }, neotest_ns)

    require("neotest").setup {
      adapters = {
        require "neotest-vitest",
        require "neotest-jest",
        require "neotest-go",
      },
    }
  end,
}
