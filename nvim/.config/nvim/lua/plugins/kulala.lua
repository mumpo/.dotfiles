-- Set the json formatter as jq to pretty print JSON responses
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function(ev)
    vim.bo[ev.buf].formatprg = "jq"
  end,
})

return {
  {
    "mistweaverco/kulala.nvim",
    keys = {
      {
        "<leader>rr",
        function()
          require("kulala").run()
        end,
        desc = "Run closest request",
      },
      {
        "<leader>rl",
        function()
          require("kulala").replay()
        end,
        desc = "Run last request",
      },
      {
        "<leader>ro",
        function()
          require("kulala").open()
        end,
        desc = "Open requests panel",
      },
      {
        "<leader>rc",
        function()
          require("kulala").close()
        end,
        desc = "Close requests panel",
      },
      {
        "<leader>ri",
        function()
          require("kulala").from_curl()
        end,
        desc = "Import cURL request from clipboard",
      },
      {
        "<leader>re",
        function()
          require("kulala").copy()
        end,
        desc = "Export cURL request to clipboard",
      },
      {
        "<leader>rs",
        function()
          require("kulala").set_selected_env()
        end,
        desc = "Set selected environment",
      },
    },
    ft = { "http", "rest" },
    opts = {},
  },
}
