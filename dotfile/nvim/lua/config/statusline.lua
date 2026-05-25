local M = {}

local progress = {}

local function escape_statusline(text)
  return tostring(text):gsub("%%", "%%%%")
end

local function truncate(text, max)
  if vim.fn.strchars(text) <= max then
    return text
  end

  return vim.fn.strcharpart(text, 0, max - 3) .. "..."
end

local function sorted_client_names(clients)
  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  table.sort(names)
  return names
end

local function diagnostic_text(bufnr)
  local counts = vim.diagnostic.count(bufnr)
  local severity = vim.diagnostic.severity
  local items = {
    { "E", counts[severity.ERROR] or 0 },
    { "W", counts[severity.WARN] or 0 },
    { "I", counts[severity.INFO] or 0 },
    { "H", counts[severity.HINT] or 0 },
  }

  local parts = {}
  for _, item in ipairs(items) do
    if item[2] > 0 then
      parts[#parts + 1] = item[1] .. ":" .. item[2]
    end
  end

  if #parts == 0 then
    return ""
  end

  return table.concat(parts, " ")
end

local function git_text(bufnr)
  local status = vim.b[bufnr].gitsigns_status_dict
  if not status or not status.head or status.head == "" then
    return ""
  end

  local parts = { "Git: " .. status.head }
  local changes = {
    { "+", status.added or 0 },
    { "~", status.changed or 0 },
    { "-", status.removed or 0 },
  }

  for _, item in ipairs(changes) do
    if item[2] > 0 then
      parts[#parts + 1] = item[1] .. item[2]
    end
  end

  return table.concat(parts, " ")
end

local function progress_text(clients)
  local client_ids = {}
  for _, client in ipairs(clients) do
    client_ids[client.id] = true
  end

  local items = {}
  for client_id, client_progress in pairs(progress) do
    if client_ids[client_id] then
      for _, item in pairs(client_progress) do
        local label = item.title or "working"
        if item.message and item.message ~= "" then
          label = label .. ": " .. item.message
        end
        if item.percentage then
          label = label .. " " .. item.percentage .. "%"
        end
        items[#items + 1] = truncate(label, 40)
      end
    end
  end

  if #items == 0 then
    return ""
  end

  table.sort(items)
  return "[" .. table.concat(items, "; ") .. "]"
end

function M.lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return escape_statusline("LSP: -")
  end

  local parts = {
    "LSP: " .. table.concat(sorted_client_names(clients), ","),
  }

  local current_progress = progress_text(clients)
  if current_progress ~= "" then
    parts[#parts + 1] = current_progress
  end

  local diagnostics = diagnostic_text(bufnr)
  if diagnostics ~= "" then
    parts[#parts + 1] = diagnostics
  end

  return escape_statusline(table.concat(parts, " "))
end

function M.git()
  return escape_statusline(git_text(vim.api.nvim_get_current_buf()))
end

function M.setup()
  _G.UserStatusline = M

  vim.opt.laststatus = 3
  vim.opt.statusline = table.concat({
    " %f",
    "%m%r%h%w",
    "%=",
    "%{v:lua.UserStatusline.git()}",
    "  ",
    "%{v:lua.UserStatusline.lsp()}",
    "  %y",
    "  %l:%c ",
  })

  local group = vim.api.nvim_create_augroup("user-statusline", { clear = true })

  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach", "DiagnosticChanged", "BufEnter" }, {
    group = group,
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitsignsUpdate",
    callback = function()
      vim.cmd.redrawstatus()
    end,
  })

  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(event)
      local client_id = event.data and event.data.client_id
      if client_id then
        progress[client_id] = nil
      end
      vim.cmd.redrawstatus()
    end,
  })

  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(event)
      local data = event.data or {}
      local params = data.params or {}
      local value = params.value or {}
      local client_id = data.client_id
      if not client_id or not value.kind then
        return
      end

      local token = tostring(params.token or "default")
      progress[client_id] = progress[client_id] or {}

      if value.kind == "end" then
        progress[client_id][token] = nil
      else
        progress[client_id][token] = {
          title = value.title,
          message = value.message,
          percentage = value.percentage,
        }
      end

      vim.cmd.redrawstatus()
    end,
  })
end

return M
