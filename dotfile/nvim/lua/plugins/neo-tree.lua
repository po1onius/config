return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  keys = {
    { "<leader>e", "<cmd>Neotree toggle reveal left<cr>", desc = "Toggle file tree" },
    { "<leader>E", "<cmd>Neotree focus reveal left<cr>", desc = "Focus file tree" },
  },
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("user-neo-tree-startup", { clear = true }),
      callback = function()
        local argc = vim.fn.argc(-1)
        local target = vim.fn.getcwd()

        if argc > 0 then
          local first_arg = vim.fn.argv(0)
          local stat = vim.uv.fs_stat(first_arg)

          if first_arg == "-" or not stat or stat.type ~= "directory" then
            return
          end

          target = vim.fn.fnamemodify(first_arg, ":p")

          if vim.bo.filetype == "netrw" or vim.fn.isdirectory(vim.api.nvim_buf_get_name(0)) == 1 then
            vim.cmd.enew()
          end
        end

        vim.cmd("Neotree focus filesystem left dir=" .. vim.fn.fnameescape(target))
      end,
    })
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    close_if_last_window = true,
    enable_diagnostics = true,
    enable_git_status = true,
    popup_border_style = "rounded",
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_ignored = false,
        hide_by_name = {
          ".git",
          ".direnv",
          ".next",
          ".nuxt",
          ".svelte-kit",
          ".turbo",
          ".venv",
          "dist",
          "node_modules",
          "result",
          "target",
        },
      },
      use_libuv_file_watcher = true,
      window = {
        mappings = {
          ["<bs>"] = "noop",
          ["."] = "noop",
        },
      },
    },
    window = {
      width = 32,
    },
  },
}
