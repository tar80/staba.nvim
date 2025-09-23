---@class helper
local M = {}

---@generic F : fun()
---@param func F
---@return fun(F)|fun()
function M.fast_event_wrap(func)
  return vim.in_fast_event() and vim.schedule_wrap(func) or func
end

---@param winid integer
---@return boolean
function M.is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ''
end

-- Function to parse a file URI and retrieve the parent directory and file name
---@param bufnr integer The buffer number
---@return string? wd The parent directory name
---@return string? filename The file name
function M.parse_path(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, nil
  end
  ---@type string,string
  local wd, name
  local uri = vim.uri_from_bufnr(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if uri:find('file://', 1, true) then
    name = path
    wd = vim.fs.dirname(path)
  else
    local scheme_end = uri:find('://', 1, true)
    if scheme_end then
      name = uri:sub(1, scheme_end) .. path:gsub('^.*[\\/]', '')
      wd = ''
    else
      name = path
      wd = ''
    end
  end
  return wd, name
end

local function _value_converter(value)
  local tbl = {}
  local t = type(value)
  if t == 'function' then
    tbl = value()
    return type(tbl) == 'table' and tbl or {}
  elseif t == 'string' then
    return { value }
  elseif t == 'table' then
    for att, _value in pairs(value) do
      local att_t = type(_value)
      if att_t == 'function' then
        _value = _value()
        if _value then
          tbl[att] = _value
        end
      end
      tbl[att] = _value
    end
    return tbl
  end
  return tbl
end

-- Set default highlights
---@param hlgroups table<string,vim.api.keyset.highlight>
function M.set_hl(hlgroups)
  vim.iter(hlgroups):each(function(name, value)
    local hl = _value_converter(value)
    hl['default'] = true
    vim.api.nvim_set_hl(0, name, hl)
  end)
end

-- Set reverse highlights
---@param hlgroups string[]
function M.set_reverse_hl(hlgroups)
  vim.iter(hlgroups):each(function(name)
    local ref_hl = vim.api.nvim_get_hl(0, { name = name, create = false })
    if ref_hl.link then
      ref_hl = vim.api.nvim_get_hl(0, { name = ref_hl.link, create = false })
    end
    local new_hl = {
      fg = ref_hl.bg,
      bg = ref_hl.fg,
    }
    if type(ref_hl.cterm) == 'table' then
      new_hl = vim.tbl_deep_extend('force', new_hl, ref_hl.cterm)
    end

    vim.api.nvim_set_hl(0, name .. 'Reverse', new_hl)
  end)
end

return M
