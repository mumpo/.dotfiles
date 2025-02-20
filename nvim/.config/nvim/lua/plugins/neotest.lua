return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "marilari88/neotest-vitest",
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
    require("neotest").setup {
      adapters = {
        require "neotest-vitest",
      },
    }
  end,
}
