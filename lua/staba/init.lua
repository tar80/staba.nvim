---@class Staba
local M = {}
local UNIQUE_NAME = 'staba.nvim'

---@param user_spec UserSpec
function M.setup(user_spec)
  local cache = require('staba.cache')
  local opts = require('staba.config').setup(UNIQUE_NAME, user_spec)
  local bufnr = vim.api.nvim_win_get_buf(0)
  cache:new(opts)
  cache:add_to_buflist(bufnr)
  cache:set_bufdata(bufnr)
  require('staba.autocmd').setup(UNIQUE_NAME, opts)
  _G.staba = {}

  if opts.tabline then
    require('staba.tabline').cache_expression(opts)
    vim.o.tabline = '%!v:lua.staba.tabline()'
    function _G.staba.tabline()
      return require('staba.tabline').decorate(cache)
    end
  end
  if opts.statusline then
    require('staba.statusline').cache_expression(opts)
    vim.o.statusline = '%{%v:lua.staba.statusline()%}'
    function _G.staba.statusline()
      return require('staba.statusline').decorate(cache)
    end
  end
  if opts.statuscolumn then
    require('staba.statuscolumn').cache_parsed_expression(opts.statuscolumn, cache:get('icons').fold)
    vim.o.statuscolumn = '%{%v:lua.staba.statuscolumn()%}'
    function _G.staba.statuscolumn()
      return require('staba.statuscolumn').decorate(cache)
    end
  end
  require('staba.keymap').setup(UNIQUE_NAME, opts, cache)
end

-- Temporarily sets NormalNC to Normal for the current window while the specified function is running.
---@param func fun(...)
---@param ... any
function M.wrap_no_fade_background(func, ...)
  vim.opt_local.winhighlight:append('NormalNC:Normal,StatuslineNC:StabaStatus')
  return func(...)
end

return M
