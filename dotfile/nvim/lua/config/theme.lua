local M = {}

local themes = {
  "tokyonight",
  "catppuccin",
  "rose-pine",
  "gruvbox",
}

local function contains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
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

