local assert = require('luassert')
local spy = require('luassert.spy')
local stub = require('luassert.stub')

describe('autocmd', function()
  local staba_autocmd
  local cache
  local UNIQUE_NAME = 'staba_test'

  local function get_mock_opts()
    return {
      ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
      enable_fade = true,
      enable_underline = false,
      hlnames = {},
      icons = {
        status = { copilot = 'A', uncopilot = 'B' },
        adjuster = ' ',
        fold = { open = '+', close = '-', blank = ' ' },
      },
      frame = {},
      sep = {},
    }
  end

  before_each(function()
    package.loaded['staba.autocmd'] = nil
    package.loaded['staba.cache'] = nil
    package.loaded['staba.config'] = nil

    staba_autocmd = require('staba.autocmd')
    cache = require('staba.cache')

    local mock_opts = get_mock_opts()
    cache:new(mock_opts)
    staba_autocmd.setup(UNIQUE_NAME, get_mock_opts())
  end)

  describe('.setup()', function()
    it('should create an augroup and register multiple autocmds', function()
      local opts = get_mock_opts()
      local s_group = stub(vim.api, 'nvim_create_augroup')
      local s_autocmd = spy.on(vim.api, 'nvim_create_autocmd')

      staba_autocmd.setup(UNIQUE_NAME, opts)
      assert.stub(s_group).was_called_with(UNIQUE_NAME, { clear = true })
      assert.spy(s_autocmd).was_called()

      s_group:revert()
      s_autocmd:revert()
    end)

    it('should handle ignore_filetypes correctly', function()
      local opts = get_mock_opts()
      opts.enable_fade = true

      assert.has_no.errors(function()
        staba_autocmd.setup(UNIQUE_NAME, opts)
      end)
    end)
  end)

  describe('.get_copilot_icon()', function()
    local icons = {
      status = { copilot = 'ON', uncopilot = 'OFF' },
      adjuster = ' ',
    }

    it('should register 2 autocmds when factory is called', function()
      local s = spy.on(vim.api, 'nvim_create_autocmd')
      s:clear()

      local render_func = staba_autocmd.get_copilot_icon(icons)
      assert.spy(s).was_called(2)
      assert.is_function(render_func)

      s:revert()
    end)

    it('should demonstrate how self-redefinition prevents double registration', function()
      local s = spy.on(vim.api, 'nvim_create_autocmd')
      s:clear()
      local M_comp = {}
      M_comp.copilot = function()
        M_comp.copilot = staba_autocmd.get_copilot_icon(icons)
        return M_comp.copilot()
      end

      M_comp.copilot()
      assert.spy(s).was_called(2)

      M_comp.copilot()
      assert.spy(s).was_called(2)

      s:revert()
    end)
  end)
end)
