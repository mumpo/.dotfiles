return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "leoluz/nvim-dap-go",
    "theHamsta/nvim-dap-virtual-text",
  },
  keys = {
    {
      "<leader>dB",
      function()
        require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
      end,
      desc = "Breakpoint Condition",
    },
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
      desc = "Toggle Breakpoint",
    },
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
      desc = "Run/Continue",
    },
    {
      "<leader>da",
      function()
        require("dap").continue { before = get_args }
      end,
      desc = "Run with Args",
    },
    {
      "<leader>dC",
      function()
        require("dap").run_to_cursor()
      end,
      desc = "Run to Cursor",
    },
    {
      "<leader>dg",
      function()
        require("dap").goto_()
      end,
      desc = "Go to Line (No Execute)",
    },
    {
      "<leader>di",
      function()
        require("dap").step_into()
      end,
      desc = "Step Into",
    },
    {
      "<leader>dj",
      function()
        require("dap").down()
      end,
      desc = "Down",
    },
    {
      "<leader>dk",
      function()
        require("dap").up()
      end,
      desc = "Up",
    },
    {
      "<leader>dl",
      function()
        require("dap").run_last()
      end,
      desc = "Run Last",
    },
    {
      "<leader>do",
      function()
        require("dap").step_out()
      end,
      desc = "Step Out",
    },
    {
      "<leader>dO",
      function()
        require("dap").step_over()
      end,
      desc = "Step Over",
    },
    {
      "<leader>dP",
      function()
        require("dap").pause()
      end,
      desc = "Pause",
    },
    {
      "<leader>dr",
      function()
        require("dap").repl.toggle()
      end,
      desc = "Toggle REPL",
    },
    {
      "<leader>dt",
      function()
        require("dap").terminate()
      end,
      desc = "Terminate",
    },

    {
      "<leader>du",
      function()
        require("dapui").toggle {}
      end,
      desc = "Toggle DAP UI",
    },
  },
  config = function()
    local dap, dapui = require "dap", require "dapui"

    require("dapui").setup()

    local icons = {
      Stopped = { " ", "DiagnosticWarn", "DapStoppedLine" },
      Breakpoint = " ",
      BreakpointCondition = " ",
      BreakpointRejected = { " ", "DiagnosticError" },
      LogPoint = ".>",
    }
    for name, sign in pairs(icons) do
      sign = type(sign) == "table" and sign or { sign }
      vim.fn.sign_define(
        "Dap" .. name,
        { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
      )
    end

    require("dap-go").setup()

    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = { vim.fn.stdpath "data" .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
      },
    }

    for _, language in ipairs { "typescript", "javascript", "typescriptreact" } do
      dap.configurations[language] = {
        {
          name = "Launch",
          type = "pwa-node",
          request = "launch",
          program = "${file}",
          rootPath = "${workspaceFolder}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
          skipFiles = { "<node_internals>/**" },
          protocol = "inspector",
          console = "integratedTerminal",
        },
        {
          name = "Launch Test Current File (pwa-node with jest)",
          type = "pwa-node",
          request = "launch",
          cwd = vim.fn.getcwd(),
          runtimeArgs = { "${workspaceFolder}/node_modules/.bin/jest" },
          runtimeExecutable = "node",
          args = { "${file}", "--coverage", "false" },
          rootPath = "${workspaceFolder}",
          sourceMaps = true,
          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        },
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch Test Program (pwa-node with vitest)",
          -- Check the closest monorepo package.json for vitest config
          cwd = function()
            local buf_path = vim.api.nvim_buf_get_name(0)
            return vim.fs.root(buf_path, "package.json") or vim.fn.getcwd()
          end,
          rootPath = "${workspaceFolder}",
          program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
          args = { "--inspect-brk", "--no-file-parallelism", "run", "${file}" },
          autoAttachChildProcesses = true,
          smartStep = true,
          console = "integratedTerminal",
          skipFiles = { "<node_internals>/**", "node_modules/**" },
        },
      }
    end

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
  end,
}
