---@diagnostic disable: undefined-field
local assert = require('luassert')
local stub = require('luassert.stub')

describe('tabline', function()
  local tabline

  local dummy_opts = {
    tabline = {
      view = { 'buffers', 'tabs' },
      active = { 'name' },
      buffers = { 'name' },
      tabs = { 'name' },
      bufinfo = { 'buffer' },
      left = { 'logo' },
      right = { 'diagnostic' },
    },
    nav_keys = 'a-s,d!f',
    no_name = '[No Name]',
    ignore_filetypes = { tabline = { 'qf', 'NvimTree' } },
  }

  local mock_cache = {
    last_tabline = '',
    bufs = {},
    get = function(self, key)
      if key == 'buflist' then
        return { 1 }
      end
      if key == 'bufdata' then
        return { cwd = '/', actual_bufnr = 1, alt_bufnr = -1 }
      end
      return {}
    end,
    set = function() end,
    clear = function() end,
    remove = function() end,
  }

  before_each(function()
    package.loaded['staba.tabline'] = nil
    package.loaded['staba.component'] = setmetatable({}, {
      __index = function()
        return function()
          return ' '
        end
      end,
    })
    package.loaded['staba.helper'] = {
      parse_path = function()
        return '/', 'test.lua'
      end,
    }
    package.loaded['staba.util'] = {
      extract_filename = function()
        return 'test.lua'
      end,
    }

    tabline = require('staba.tabline')
  end)

  describe('.cache_expression()', function()
    it('initializes internal variables from opts without error', function()
      assert.has_no.errors(function()
        tabline.cache_expression(dummy_opts)
      end)
    end)

    it('gracefully handles missing ignore_filetypes.tabline', function()
      local sparse_opts = vim.deepcopy(dummy_opts)
      sparse_opts.ignore_filetypes = {}
      assert.has_no.errors(function()
        tabline.cache_expression(sparse_opts)
      end)
    end)
  end)

  describe('.decorate()', function()
    before_each(function()
      tabline.cache_expression(dummy_opts)
    end)

    it('generates a valid tabline string using the provided cache', function()
      stub(vim.api, 'nvim_list_tabpages', function()
        return { 1 }
      end)
      stub(vim.api, 'nvim_win_get_config', function()
        return {}
      end)
      stub(vim.api, 'nvim_get_option_value', function(name)
        if name == 'shellslash' then
          return true
        end
        return ''
      end)
      stub(vim.fn, 'tabpagebuflist', function()
        return { 1 }
      end)
      stub(vim.fn, 'tabpagewinnr', function()
        return 1
      end)
      stub(vim.fn, 'tabpagenr', function()
        return 1
      end)

      local res = tabline.decorate(mock_cache)

      assert.is_string(res)
      assert.is_not.equal('', res)
      assert.is_not_nil(res:match('%%'))
      assert.are.equal(res, mock_cache.last_tabline)

      vim.api.nvim_list_tabpages:revert()
      vim.api.nvim_win_get_config:revert()
      vim.api.nvim_get_option_value:revert()
      vim.fn.tabpagebuflist:revert()
      vim.fn.tabpagewinnr:revert()
      vim.fn.tabpagenr:revert()
    end)

    it('returns last_tabline if in a floating window (skip logic)', function()
      stub(vim.api, 'nvim_win_get_config', function()
        return { anchor = 'NW' }
      end)
      stub(vim.api, 'nvim_get_option_value', function()
        return 'lua'
      end)

      mock_cache.last_tabline = 'PREVIOUS_RENDER'

      local res = tabline.decorate(mock_cache)
      assert.are.equal('PREVIOUS_RENDER', res)

      vim.api.nvim_win_get_config:revert()
      vim.api.nvim_get_option_value:revert()
    end)
  end)
end)
