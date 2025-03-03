---@class Staba
local M = {}
local PLUGIN_NAME = 'staba.nvim'

---@param user_spec UserSpec
function M.setup(user_spec)
  local cache = require('staba.cache')
  local opts = require('staba.config').setup(user_spec)
  local bufnr = vim.api.nvim_win_get_buf(0)
  cache:new(opts)
  cache:add_to_buflist(bufnr)
  cache:set_bufdata(bufnr)
  require('staba.autocmd').setup(PLUGIN_NAME, opts)
  _G.staba = {}

  if opts.tabline then
    require('staba.keymap').setup(PLUGIN_NAME)
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
end

return M
