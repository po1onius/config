return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "^" },
      changedelete = { text = "~" },
      untracked = { text = "?" },
    },
    signs_staged = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "^" },
      changedelete = { text = "~" },
      untracked = { text = "?" },
    },
    signs_staged_enable = true,
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    watch_gitdir = {
      follow_files = true,
    },
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol",
      delay = 500,
      ignore_whitespace = false,
    },
    preview_config = {
      border = "rounded",
      style = "minimal",
      relative = "cursor",
      row = 0,
      col = 1,
    },
    max_file_length = 40000,
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
      end

      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, "Next git hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, "Previous git hunk")

      -- map("n", "<leader>gs", gitsigns.stage_hunk, "Stage git hunk")
      map("n", "<leader>gr", gitsigns.reset_hunk, "Reset git hunk")
      map("v", "<leader>gs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Stage selected git hunk")
      map("v", "<leader>gr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Reset selected git hunk")

      map("n", "<leader>gS", gitsigns.stage_buffer, "Stage git buffer")
      map("n", "<leader>gR", gitsigns.reset_buffer, "Reset git buffer")
      map("n", "<leader>gu", gitsigns.undo_stage_hunk, "Undo stage git hunk")
      map("n", "<leader>gp", gitsigns.preview_hunk, "Preview git hunk")
      map("n", "<leader>gb", function()
        gitsigns.blame_line({ full = true })
      end, "Git blame line")
      map("n", "<leader>gB", gitsigns.toggle_current_line_blame, "Toggle git line blame")
      map("n", "<leader>gd", gitsigns.diffthis, "Git diff buffer")
      map("n", "<leader>gD", function()
        gitsigns.diffthis("~")
      end, "Git diff buffer against previous commit")
      map("n", "<leader>gq", gitsigns.setqflist, "Git hunks quickfix")
      map({ "o", "x" }, "ih", gitsigns.select_hunk, "Git hunk")
    end,
  },
}
