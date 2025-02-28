local M = {}

---@type StatusColumnTable
local expression
local has_fold_ex = false

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
function M.cache_parsed_expression(statuscolumn)
  local active = ''
  local inactive = ''
  local blank_space = statuscolumn[#statuscolumn] == 'number' and ' ' or ''
  vim.iter(statuscolumn):each(function(ele)
    active = active .. formatter.active[ele]
    inactive = inactive .. formatter.inactive[ele]
  end)

  expression = { active = active .. blank_space, inactive = inactive .. blank_space }
  has_fold_ex = vim.list_contains(statuscolumn, 'fold_ex')
end

---@return string fold-marker
local function get_folding(has_tsnode, fold, marker)
  if vim.fn.foldclosed(vim.v.lnum) >= 0 then
    marker = fold.close
  elseif has_tsnode and tostring(vim.treesitter.foldexpr(vim.v.lnum)):sub(1, 1) == '>' then
    marker = fold.open
  end
  return marker
end

---@param cache Cache
---@return string expression
function M.decorate(cache)
  ---@type string
  local statuscolumn
  local fold_icon = cache:get('icons').fold
  local bufdata = cache:get('bufdata')
  local marker = has_fold_ex and fold_icon.blank or ''
  local winid = tonumber(vim.g.actual_curwin) --[[@as integer]]
  local bufnr = vim.api.nvim_win_get_buf(winid)

  if bufdata.actual_bufnr == bufnr then
    if has_fold_ex then
      local fold_marker = get_folding(bufdata.has_tsnode, fold_icon, marker)
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
