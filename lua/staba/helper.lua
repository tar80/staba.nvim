---@meta helper
---@class helper
local M = {}

---@param winid integer
---@return boolean
function M.is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ''
end

-- Function to parse a file URI and retrieve the parent directory and file name
---@param bufnr integer The buffer number
---@return string wd The parent directory name
---@return string filename The file name
function M.parse_path(bufnr)
  ---@type string,string
  local wd, name
  local path = vim.uri_from_bufnr(bufnr)
  if path:find('file://', 1, true) then
    name = path:gsub('file:///?', '')
    wd = vim.fs.dirname(name)
  else
    local scheme_end = path:find('://', 1, true)
    if scheme_end then
      name = path:sub(1, scheme_end) .. path:sub(scheme_end):gsub('^.*[\\/]', '')
      wd = ''
    else
      name = path
      wd = ''
    end
  end
  return wd, name
end

-- Set default highlights
---@param hlgroups table<string,vim.api.keyset.highlight>
function M.set_hl(hlgroups)
  vim.iter(hlgroups):each(function(name, value)
    local hl = type(value) == 'function' and value() or value
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
