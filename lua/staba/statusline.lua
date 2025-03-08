---@class Statusline
local M = {}
local component = require('staba.component')
local util = require('staba.util')

local expression ---@type StatuslineTable
local no_name ---@type string
local status_ignore ---@type table

local function parse_component(tbl, bufs)
  local exp = ''
  vim.iter(tbl):each(function(element)
    local _component = component[element]
    local element_type = type(element)
    ---@type string
    local value
    if _component then
      value = _component(bufs, true)
    elseif element_type == 'function' then
      value = element()
    else
      value = tostring(element)
    end
    exp = exp .. value
  end)
  return exp
end

---@param tbl StatuslineSection
local function parse_section(tbl, bufs)
  local exp = {}
  if tbl.left then
    local v = parse_component(tbl.left, bufs)
    vim.list_extend(exp, { v })
  end
  if tbl.middle then
    local v = parse_component(tbl.middle, bufs)
    vim.list_extend(exp, { v })
  end
  if tbl.right then
    local v = parse_component(tbl.right, bufs)
    vim.list_extend(exp, { v })
  end
  return vim.fn.join(exp, '%=')
end

---@param opts Options
function M.cache_expression(opts)
  expression = opts.statusline
  no_name = opts.no_name
  status_ignore = opts.ignore_filetypes.statusline or {}
end

---@param cache Cache
---@return string expression
function M.decorate(cache)
  local actual_win = tonumber(vim.g.actual_curwin) --[[@as integer]]
  local cur_win = vim.api.nvim_get_current_win()
  local cur_buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(cur_buf)
  local is_popup = vim.api.nvim_win_get_config(actual_win).anchor
  local buf_status = {
    parent = util.extract_filename(vim.fs.dirname(name)),
    name = name,
    no_name = no_name,
    bufnr = cur_buf,
    buftype = vim.api.nvim_get_option_value('buftype', { buf = cur_buf }),
    shellslash = vim.api.nvim_get_option_value('shellslash', {}) and '/' or '\\',
    mode = cache:get('mode'),
  }
  local ft = vim.api.nvim_get_option_value('filetype', { buf = cur_buf })
  if vim.list_contains(status_ignore, ft) then
    return ''
  elseif actual_win == cur_win then
    cache.last_statusline_win = cur_win
    return parse_section(expression.active, buf_status)
  elseif is_popup and cache.last_statusline_win == cur_win then
    return parse_section(expression.active, buf_status)
  else
    return parse_section(expression.inactive, buf_status)
  end
end

return M
