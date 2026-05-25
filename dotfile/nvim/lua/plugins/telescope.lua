return {
  "nvim-telescope/telescope.nvim",
  version = "*",
  cmd = "Telescope",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  keys = {
    {
      "<leader>sg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Search text in project",
    },
    {
      "<leader>sw",
      function()
        require("telescope.builtin").grep_string()
      end,
      desc = "Search word under cursor",
    },
    {
      "<leader>sf",
      function()
        require("telescope.builtin").find_files()
      end,
      desc = "Search files",
    },
    {
      "<leader>sr",
      function()
        require("telescope.builtin").oldfiles()
      end,
      desc = "Search recent files",
    },
    {
      "<leader>sb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Search buffers",
    },
    {
      "<leader>sh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Search help",
    },
  },
  opts = function()
    local actions = require("telescope.actions")

    return {
      defaults = {
        prompt_prefix = "> ",
        selection_caret = "> ",
        path_display = { "smart" },
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          horizontal = {
            preview_width = 0.55,
          },
        },
        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
          n = {
            ["q"] = actions.close,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        live_grep = {
          additional_args = function()
            return { "--hidden", "--glob", "!**/.git/*" }
          end,
        },
        grep_string = {
          additional_args = function()
            return { "--hidden", "--glob", "!**/.git/*" }
          end,
        },
      },
    }
  end,
  config = function(_, opts)
    local telescope = require("telescope")

    telescope.setup(opts)

    pcall(telescope.load_extension, "fzf")
  end,
}
