local M = {}

---@type StatusColumnTable
local expression
local _has_fold_ex = false
local _fold_icon = {}

local formatter = {
  active = {
    sign = '%%#SignColumn#%%s',
    number = '%%l',
    fold = '%%#FoldColumn#%%C',
    fold_ex = '%%#FoldColumn#%s',
  },
  inactive = {
    sign = '%%#SignColumn#%%s',
    number = '%%=%%{v:lnum}',
    fold = '%%#FoldColumn#%%C',
    fold_ex = '%%#FoldColumn#%s',
  },
}

---@param statuscolumn statusColumn[]
---@param fold_icon IconsFold
function M.cache_parsed_expression(statuscolumn, fold_icon)
  local active = ''
  local inactive = ''
  local blank_space = statuscolumn[#statuscolumn] == 'number' and ' ' or ''
  vim.iter(statuscolumn):each(function(ele)
    active = active .. formatter.active[ele]
    inactive = inactive .. formatter.inactive[ele]
  end)

  expression = { active = active .. blank_space, inactive = inactive .. blank_space }
  _has_fold_ex = vim.list_contains(statuscolumn, 'fold_ex')
  _fold_icon = fold_icon
end

---@param fold IconsFold
---@param marker string Icon string
---@return string fold-marker
local function get_folding(fold, marker)
  local is_actual_line = vim.v.virtnum ~= 0
  local lnum = vim.v.lnum
  if vim.fn.foldclosed(lnum) >= 0 then
    marker = fold.close

  ---@source https://github.com/folke/snacks.nvim/issues/1445
  elseif is_actual_line and  vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
    marker = fold.open
  end
  return marker
end

---@param cache Cache
---@return string expression
function M.decorate(cache)
  ---@type string
  local statuscolumn
  local bufdata = cache:get('bufdata')
  local marker = _has_fold_ex and _fold_icon.blank or ''
  local winid = tonumber(vim.g.actual_curwin) --[[@as integer]]
  local bufnr = vim.api.nvim_win_get_buf(winid)

  if bufdata.actual_bufnr == bufnr then
    if _has_fold_ex then
      local fold_marker = get_folding(_fold_icon, marker)
      statuscolumn = expression.active:format(fold_marker)
    else
      statuscolumn = expression.active:format()
    end
  else
    statuscolumn = expression.inactive:format(marker)
  end

  return statuscolumn
end

return M
