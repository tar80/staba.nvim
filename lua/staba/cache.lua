local M = {}
--[[
  Copyright 2025 folke

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]
local devicons = (function()
  local mod = nil
  local function load()
    if not mod then
      mod = require('nvim-web-devicons')
      package.loaded['nvim-web-devicons'] = mod
    end
    return mod
  end
  return vim.g.loaded_devicons and package.loaded['nvim-web-devicons']
    or setmetatable({}, {
      __index = function(_, key)
        return load()[key]
      end,
      __call = function(_, ...)
        return load()(...)
      end,
    })
end)()

---@param name string
---@return IconDetail
local function get_devicon(name)
  local ret = { chr = '', hlgroup = '' }
  if name ~= '' then
    local extension = require('staba.util').extract_fileext(name)
    local chr, hlgroup = devicons.get_icon(name, extension, { default = true })
    if chr then
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
  self.frame = opts.frame
  self.sep = opts.sep
  self.ignore_filetypes = opts.ignore_filetypes
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

-- for compatibility version 0.10
local _ts_get_node = (function ()
  local get_node = vim.treesitter.get_node
  local f ---@type function
  if vim.fn.has('nvim-0.11') == 1 then
    f = get_node
  else
    f = function ()
      local _, ts_node = pcall(get_node)
      return ts_node
    end
  end
  return f
end)()

function M:set_bufdata(bufnr)
  ---@type BufData
  self.bufdata = {
    cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
    winid = vim.api.nvim_tabpage_get_win(0),
    actual_bufnr = bufnr,
    alt_bufnr = vim.fn.bufnr('#'),
    has_tsnode = _ts_get_node() or false
  }
end

return setmetatable({}, { __index = M })
