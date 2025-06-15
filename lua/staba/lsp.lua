local M = {}
local lsp = vim.lsp

---@generic serverName string
---@alias ServerNames serverName[]

---@class ServerDetails table<serverName,vim.lsp.client>

---@class Clients :ServerDetails
---@field count integer
---@field names ServerNames
---@field ids integer[]

---@return Clients
function M.buf_get_clients()
  local clients = lsp.get_clients({ bufnr = 0 })
  local t = {
    count = #clients,
    names = {},
    ids = {}
  }
  vim.iter(clients):each(function(client)
    local name = client.name
    local id = client.id
    table.insert(t.names, name)
    table.insert(t.ids, id)
    t[name] = client
  end)
  return t
end

---@param clients Clients
function M.buf_detach_clients(clients)
  vim.iter(clients.ids):each(function(id)
    lsp.buf_detach_client(0,id)
  end)
end

return M
