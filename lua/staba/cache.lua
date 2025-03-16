local M = {}

---@param name string
---@return IconDetail
local function get_devicon(name)
  local ret = { chr = '', hlgroup = '' }
  if name ~= '' then
    local extension = require('staba.util').extract_fileext(name)
    local devicons = package.loaded['nvim-web-devicons']
    if devicons then
      local chr, hlgroup = devicons.get_icon(name, extension, { default = true })
      ret = { chr = chr, hlgroup = hlgroup }
    end
  end
  return ret
end

---@param items string|string[]
local function expand_icon(items)
  vim.iter(items):each(function(item, value)
    local t1 = type(value)
    if t1 == 'string' then
      items[item] = value
      return
    elseif t1 ~= 'table' then
      vim.notify('', vim.log.levels.ERROR, {})
      return
    end
    for k, v in pairs(value) do
      local t2 = type(v)
      if t2 == 'string' then
        if k == 1 then
          local hl = value[2] and ('%%#%s#'):format(value[2]) or ''
          items[item] = hl .. v
        end
      elseif t2 ~= 'table' then
        vim.notify('', vim.log.levels.ERROR, {})
        return
      else
        local hl = v[2] and ('%%#%s#'):format(v[2]) or ''
        items[item][k] = hl .. v[1]
      end
    end
  end)
  return items
end

---@param opts Options
function M:new(opts)
  self.hlnames = opts.hlnames
  self.icons = expand_icon(opts.icons)
  self.ignore_filetypes = opts.ignore_filetypes
  self.frame = opts.frame
  self.sep = opts.sep
  self.bufs = {}
  self.buflist = {}
  self.buf_id = {}
  self.mode = {}
end

function M:set(name, tbl)
  self[name] = vim.tbl_deep_extend('force', self[name], tbl)
end

function M:clear(name, value)
  self[name] = value
end

function M:remove(name, value)
  self[name] = vim
    .iter(self[name])
    :filter(function(v)
      return v ~= value
    end)
    :totable()
end

function M:get(name)
  return self[name]
end

function M:eq(name, actual, expect)
  return self[name][actual] == expect
end

function M:add_to_buflist(bufnr)
  if not vim.list_contains(self.buflist, bufnr) then
    table.insert(self.buflist, bufnr)
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  self.bufs[bufnr] = {
    name = name,
    devicon = get_devicon(name),
  }
end

function M:set_bufdata(bufnr)
  ---@type BufData
  self.bufdata = {
    cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
    winid = vim.api.nvim_tabpage_get_win(0),
    actual_bufnr = bufnr,
    alt_bufnr = vim.fn.bufnr('#'),
    mark = {},
  }
end

return setmetatable({}, { __index = M })
