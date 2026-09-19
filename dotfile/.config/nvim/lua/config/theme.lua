local M = {}

local themes = {
  "tokyonight",
  "catppuccin",
  "rose-pine",
  "gruvbox",
}

local transparent_groups = {
  "Normal",
  "NormalNC",
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "CursorLineNr",
  "EndOfBuffer",
  "MsgArea",
  "StatusLine",
  "StatusLineNC",
  "WinSeparator",
  "Pmenu",
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeEndOfBuffer",
  "LazyNormal",
}

local completion_selection = {
  fg = "#ffffff",
  bg = "#3d59a1",
  bold = true,
}

local completion_border = {
  fg = "#7aa2f7",
  bg = "NONE",
}

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

function M.apply_transparency()
  if vim.g.transparent_background == false then
    return
  end

  for _, group in ipairs(transparent_groups) do
    vim.cmd.highlight({ args = { group, "guibg=NONE", "ctermbg=NONE" } })
  end
end

function M.apply_completion_highlights()
  vim.api.nvim_set_hl(0, "CmpBorder", completion_border)
  vim.api.nvim_set_hl(0, "PmenuSel", completion_selection)
  vim.api.nvim_set_hl(0, "PmenuKindSel", completion_selection)
  vim.api.nvim_set_hl(0, "PmenuExtraSel", completion_selection)
end

function M.apply_overrides()
  M.apply_transparency()
  M.apply_completion_highlights()
end

function M.set(name)
  if not contains(themes, name) then
    vim.notify("Unknown theme: " .. name, vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("Unable to load theme " .. name .. ": " .. err, vim.log.levels.ERROR)
    return
  end

  M.apply_overrides()
  vim.g.user_theme = name
end

function M.cycle()
  local current = vim.g.colors_name or vim.g.user_theme or themes[1]
  local index = 1

  for i, name in ipairs(themes) do
    if name == current then
      index = i
      break
    end
  end

  local next_index = index % #themes + 1
  M.set(themes[next_index])
end

function M.setup()
  vim.g.transparent_background = vim.g.transparent_background ~= false

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("user-transparent-background", { clear = true }),
    callback = M.apply_overrides,
  })

  vim.api.nvim_create_user_command("Theme", function(args)
    M.set(args.args)
  end, {
    nargs = 1,
    complete = function(arg_lead)
      return vim.tbl_filter(function(name)
        return vim.startswith(name, arg_lead)
      end, themes)
    end,
  })

  vim.keymap.set("n", "<leader>ut", M.cycle, { desc = "Cycle theme" })

  M.set(vim.g.user_theme or themes[1])
end

return M
