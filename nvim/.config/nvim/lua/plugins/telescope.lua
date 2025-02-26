return {
  "nvim-telescope/telescope.nvim",
  cmd = { "Telescope" },
  tag = "0.1.8",
  -- or                              , branch = '0.1.x',
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>fF",
      "<cmd>Telescope find_files no_ignore=true hidden=true<cr>",
      desc = "File search (with hidden and .gitignored)",
    },
    {
      "<leader>fb",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end,
      desc = "Fuzzy buffer search",
    },
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "File search" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep search" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
    { "<leader>fr", "<cmd>Telescope oldfiles only_cwd=true<cr>", desc = "Recently opened files" },
  },
  config = function()
    local telescope = require "telescope"
    local telescopeConfig = require "telescope.config"
    local actions = require "telescope.actions"

    -- Clone the default Telescope configuration
    local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

    -- I want to search in hidden/dot files.
    table.insert(vimgrep_arguments, "--hidden")
    -- I don't want to search in the `.git` directory.
    table.insert(vimgrep_arguments, "--glob")
    table.insert(vimgrep_arguments, "!**/.git/*")
    require("telescope").setup {
      defaults = {
        -- `hidden = true` is not supported in text grep commands.
        vimgrep_arguments = vimgrep_arguments,
        mappings = {
          i = {
            ["<esc>"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
    }
  end,
}
