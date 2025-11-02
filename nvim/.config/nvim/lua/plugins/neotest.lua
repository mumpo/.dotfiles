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
    "fredrikaverpil/neotest-golang",
    "mrcjkb/rustaceanvim",
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
        "<leader>tl",
        function()
          neotest.run.last()
        end,
        desc = "Run last test",
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
        require "neotest-vitest" {
          cwd = function(testFilePath)
            -- Run this in the context of a monorepo app/package.
            return vim.fs.root(testFilePath, "package.json")
          end,
        },
        require "neotest-jest",
        require "neotest-golang",
        require "rustaceanvim.neotest",
      },
      icons = {
        expanded = "",
        child_prefix = "",
        child_indent = " ",
        final_child_prefix = "",
        non_collapsible = "",
        collapsed = "",

        passed = "",
        running = "",
        failed = "",
        unknown = "",
      },
      highlights = {
        adapter_name = "Bold",
        dir = "Function",
        file = "Function",
      },
      summary = {
        -- I keep getting these errors when running tests:
        -- neotest/lua/neotest/consumers/summary/init.lua:55: E5560: nvim_create_autocmd must not be called in a fast event context
        -- Until I know how to fix this, I will disable the follow feature.
        follow = true,
      },
      floating = {
        border = "rounded",
      },
      consumers = {
        notify = function(client)
          local notify = require "notify"
          local current_notify
          local current_pos

          client.listeners.run = function(adapter_id, pos)
            current_pos = pos
            current_notify = notify(pos, "info", { title = "Running test", timeout = 20000, icon = "󰚭" })
          end

          client.listeners.results = function(adapter_id, results)
            if not current_pos then
              return
            end

            local result = results[current_pos]

            if result then
              if result.status == "passed" then
                notify(
                  current_pos,
                  "info",
                  { title = "Test passed", icon = "", replace = current_notify, timeout = 3000 }
                )
              else
                notify(current_pos, "error", { title = "Test failed", replace = current_notify, timeout = 3000 })
              end

              current_pos = nil
              current_notify = nil
            end
          end
        end,
      },
    }
  end,
}
