---@class Tabline
local M = {}
local component = require('staba.component')
local util = require('staba.util')
local helper = require('staba.helper')

-- cache variables
local expression ---@type TablineTable
local has_tabs ---@type boolean
local has_buffers ---@type boolean
local register_keys ---@type string[]
local no_name ---@type string
local tab_ignore ---@type table

---@return {current:string,contains:string[]}
local function get_tabpage_details()
  local current = {}
  local contains = {}
  for index = 1, #vim.api.nvim_list_tabpages() do
    local buflist = vim.fn.tabpagebuflist(index)
    local winnr = vim.fn.tabpagewinnr(index)
    local bufnr = buflist[winnr]
    current[bufnr] = index
    contains = vim.list_extend(contains, buflist)
  end
  return { current = current, contains = contains }
end

---@param bufnr integer
---@return string? unopened
local function unopened_arglist_file(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return vim.iter(vim.fn.argv()):find(function(name)
      return vim.fn.bufnr(name) == bufnr
    end)
  end
end

local function parse_component(tbl, buf_info)
  local exp = ''
  vim.iter(tbl):each(function(element)
    local _component = component[element]
    local element_type = type(element)
    ---@type string
    local value
    if _component then
      value = _component(buf_info)
    elseif element_type == 'function' then
      value = element(buf_info)
    else
      value = tostring(element)
    end
    exp = exp .. value
  end)
  return exp
end

local function parse_tab(keyspec, tbl, buf_status, is_active)
  local exp = ''
  vim.iter(tbl):each(function(element)
    local _component = component[element]
    local element_type = type(element)
    ---@type string
    local value = ''
    if _component then
      buf_status.nav_key = keyspec
      value = _component(buf_status, is_active)
    elseif element_type == 'function' then
      value = element(buf_status, is_active)
    else
      value = tostring(element)
    end
    exp = exp .. value
  end)
  return exp .. ' '
end

local function parse_expression(cache, bufdata)
  local keys = vim.deepcopy(register_keys)
  local alt_key = keys[1]
  if bufdata.alt_bufnr ~= -1 then
    table.remove(keys, 1)
  end
  return function(bufnr, status, key, method, ctx)
    if not key then
      if status.alternate then
        key = alt_key
      else
        key = keys[1]
        if not key then
          return ''
        end
        table.remove(keys, 1)
      end
    end
    local exp = ctx .. parse_tab(key, expression[method], status)
    cache:set('buf_id', { [key] = bufnr })
    return exp
  end
end

---@param opts Options
function M.cache_expression(opts)
  expression = opts.tabline
  register_keys = vim.split(opts.nav_keys:gsub('[^%a]', ''), '')
  no_name = opts.no_name
  has_tabs = vim.tbl_contains(expression.view, 'tabs')
  has_buffers = vim.tbl_contains(expression.view, 'buffers')
  tab_ignore = opts.ignore_filetypes.tabline or {}
end

---@param cache Cache
---@return string expression
function M.decorate(cache)
  do
    local skip_popup = vim.api.nvim_win_get_config(0).anchor
    if skip_popup then
      return cache.last_tabline
    end
  end
  cache:clear('buf_id', {})
  local buflist = cache:get('buflist')
  local bufdata = cache:get('bufdata')
  local tabpage = get_tabpage_details()
  local shellslash = vim.api.nvim_get_option_value('shellslash', {}) and '/' or '\\'
  ---@type BufInfo
  local buf_info = {
    buffer = 0,
    modified = 0,
    unopened = 0,
    cwd = bufdata.cwd,
    format = expression.bufinfo,
    shellslash = shellslash,
    tab = vim.fn.tabpagenr('$'),
  }
  local left, right, view, active, alternate = '', '', '', '', ''
  local list = { tabs = '', buffers = '' }
  local get_exp = parse_expression(cache, bufdata)
  vim.iter(buflist):each(function(bufnr)
    local is_active = bufdata.actual_bufnr == bufnr
    local is_alternate = bufdata.alt_bufnr == bufnr
    if not vim.api.nvim_buf_is_valid(bufnr) then
      cache:remove('buflist', bufnr)
      cache.bufs[bufnr] = nil
      return
    end
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
    if vim.list_contains(tab_ignore, filetype) then
      return
    end
    local tabnr = tabpage.current[bufnr]
    local tab_current = type(tabnr) == 'number'
    local wd, name = helper.parse_path(bufnr)
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
    local modified = vim.api.nvim_get_option_value('modified', { buf = bufnr })
    local readonly = vim.api.nvim_get_option_value('readonly', { buf = bufnr })
      or not vim.api.nvim_get_option_value('modifiable', { buf = bufnr })
    local unopened = unopened_arglist_file(bufnr)

    ---@type BufferStatus
    local buf_status = {
      parent = bufdata.cwd ~= wd and util.extract_filename(wd) or '',
      name = name,
      no_name = no_name,
      has_name = name ~= '',
      bufnr = bufnr,
      buftype = buftype,
      filetype = filetype,
      modified = modified,
      readonly = readonly,
      unopened = unopened,
      shellslash = shellslash,
      tabnr = tabnr,
      nav_key = '',
    }

    buf_info.buffer = buf_info.buffer + 1
    if modified then
      buf_info.modified = buf_info.modified + 1
    end
    if unopened then
      buf_info.unopened = buf_info.unopened + 1
    end

    if is_active then
      active = parse_tab('', expression.active, buf_status, true)
    elseif is_alternate then
      buf_status.alternate = true
      alternate = get_exp(bufnr, buf_status, false, 'buffers', '')
    elseif tabnr ~= vim.fn.tabpagenr() and has_buffers then
      list.buffers = get_exp(bufnr, buf_status, false, 'buffers', list.buffers)
    end
    if tab_current and has_tabs and not is_active then
      list.tabs = get_exp(bufnr, buf_status, tostring(tabnr), 'tabs', list.tabs)
    end
  end)

  if expression.left then
    left = parse_component(expression.left, buf_info)
  end
  if expression.right then
    right = parse_component(expression.right, buf_info)
  end
  if expression.view[1] then
    view = view .. list[expression.view[1]]
  end
  if expression.view[2] then
    view = view .. list[expression.view[2]]
  end

  local exp = left .. active .. alternate .. view .. '%*%<%=' .. right
  cache.last_tabline = exp

  return exp
end

return M
