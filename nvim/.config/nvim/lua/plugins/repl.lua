return {
  "Vigemus/iron.nvim",
  keys = function()
    local iron = function()
      return require "iron.core"
    end
    return {
      {
        "<space>ir",
        function()
          iron().repl_restart()
        end,
        desc = "Restart REPL",
      },
      {
        "<space>iv",
        function()
          iron().visual_send()
        end,
        mode = { "n", "v" },
        desc = "Send selection to REPL",
      },
      {
        "<space>if",
        function()
          iron().send_file()
        end,
        desc = "Send file to REPL",
      },
      {
        "<space>il",
        function()
          iron().send_line()
        end,
        desc = "Send line to REPL",
      },
      {
        "<space>ib",
        function()
          iron().send_code_block()
        end,
        desc = "Send code block to REPL",
      },
      {
        "<space>sn",
        function()
          iron().send_code_block_and_move()
        end,
        desc = "Send code block and move",
      },
      {
        "<space>iq",
        function()
          iron().close_repl()
        end,
        desc = "Close REPL",
      },
    }
  end,
  config = function()
    local iron = require "iron.core"
    local view = require "iron.view"
    local common = require "iron.fts.common"

    iron.setup {
      config = {
        -- Whether a repl should be discarded or not
        scratch_repl = true,
        -- Your repl definitions come here
        repl_definition = {
          sh = {
            -- Can be a table or a function that
            -- returns a table (see below)
            command = { "zsh" },
          },
          python = {
            -- Let uv figure out the context automatically
            command = { "uv", "run", "--with", "ipython", "--with", "requests", "ipython", "--no-confirm-exit" },
            format = common.bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
          },
        },
        -- set the file type of the newly created repl to ft
        -- bufnr is the buffer id of the REPL and ft is the filetype of the
        -- language being used for the REPL.
        repl_filetype = function(bufnr, ft)
          return ft
          -- or return a string name such as the following
          -- return "iron"
        end,
        -- Send selections to the DAP repl if an nvim-dap session is running.
        dap_integration = true,
        -- How the repl window will be displayed
        -- See below for more information
        repl_open_cmd = view.split.vertical.botright "40%",
      },
      -- If the highlight is on, you can change how it looks
      -- For the available options, check nvim_set_hl
      highlight = {
        italic = true,
      },
      ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
    }
  end,
}
