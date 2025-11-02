return {
  "nvim-telescope/telescope.nvim",
  cmd = { "Telescope" },
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-live-grep-args.nvim" },
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
    { "<leader>fg", ":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", desc = "Grep search" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
    { "<leader>fr", "<cmd>Telescope oldfiles only_cwd=true<cr>", desc = "Recently opened files" },
    { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
    { "<leader>fw", "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "Workspace symbols" },
  },
  config = function()
    local telescope = require "telescope"
    local telescopeConfig = require "telescope.config"
    local actions = require "telescope.actions"
    local lga_actions = require "telescope-live-grep-args.actions"

    -- Load the fzf native extension for better performance
    -- telescope.load_extension "fzf"

    -- Clone the default Telescope configuration
    local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

    -- I want to search in hidden/dot files.
    table.insert(vimgrep_arguments, "--hidden")
    -- I don't want to search in the `.git` directory.
    table.insert(vimgrep_arguments, "--glob")
    table.insert(vimgrep_arguments, "!**/.git/*")

    telescope.setup {
      defaults = {
        -- This makes it so clear to see first the file name and then the path
        path_display = { "filename_first" },
        -- `hidden = true` is not supported in text grep commands.
        vimgrep_arguments = vimgrep_arguments,
        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<C-i>"] = lga_actions.quote_prompt { postfix = " --iglob " },
            ["<C-f>"] = actions.to_fuzzy_refine,
          },
        },
      },
      pickers = {
        find_files = {
          -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
      },
      extensions = {
        live_grep_args = {
          mappings = {
            i = {
              ["<C-f>"] = lga_actions.to_fuzzy_refine,
            },
          },
        },
      },
    }

    telescope.load_extension "live_grep_args"
  end,
}
