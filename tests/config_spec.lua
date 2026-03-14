---@diagnostic disable: undefined-field
local assert = require('luassert')
local stub = require('luassert.stub')

describe('config', function()
  local config
  local helper

  before_each(function()
    package.loaded['staba.config'] = nil
    package.loaded['staba.helper'] = nil
    package.loaded['staba.icon'] = nil
    package.loaded['staba.icon.ui'] = nil

    helper = require('staba.helper')
    stub(helper, 'set_hl')
    stub(vim.api, 'nvim_get_hl', function()
      return { fg = 0, bg = 0 }
    end)
    stub(vim.api, 'nvim_set_hl')
    stub(vim.api, 'nvim_set_var')

    config = require('staba.config')
  end)

  after_each(function()
    helper.set_hl:revert()
    vim.api.nvim_get_hl:revert()
    vim.api.nvim_set_hl:revert()
    vim.api.nvim_set_var:revert()
  end)

  describe('M.setup()', function()
    it('returns default options when user_spec is empty', function()
      local user_spec = {
        enable_statusline = true,
        enable_tabline = true,
      }

      local opts = config.setup('STABA_TEST', user_spec)

      assert.is_table(opts)
      assert.are.equal('asdfghjklzxcvnmweryuiop', opts.nav_keys)
      assert.are.equal('[No Name]', opts.no_name)

      assert.is_table(opts.statusline)
      assert.is_not_nil(opts.statusline.active)
      assert.is_table(opts.tabline)
    end)

    it('overrides default values with user_spec values', function()
      local user_spec = {
        no_name = 'EMPTY_FILE',
        nav_keys = 'abc',
        enable_statusline = true,
        statusline = {
          active = { left = { 'custom_component' } },
        },
      }

      local opts = config.setup('STABA_TEST', user_spec)

      assert.are.equal('EMPTY_FILE', opts.no_name)
      assert.are.equal('abc', opts.nav_keys)
      assert.are.equal('custom_component', opts.statusline.active.left[1])
    end)

    it('sets up highlights when flags are enabled', function()
      local user_spec = {
        enable_tabline = true,
        enable_statusline = true,
        enable_fade = true,
        enable_underline = true,
      }

      config.setup('STABA_TEST', user_spec)

      assert.stub(helper.set_hl).was_called()
      assert.stub(vim.api.nvim_set_var).was_called_with('showtabline', 2)
    end)

    it('correctly handles mode_line configuration', function()
      local user_spec = {
        mode_line = 'CursorLineNr',
      }

      local opts = config.setup('STABA_TEST', user_spec)
      assert.are.equal('CursorLineNr', opts.mode_line)

      local bad_spec = { mode_line = 'InvalidHL' }
      local bad_opts = config.setup('STABA_TEST', bad_spec)
      assert.is_nil(bad_opts.mode_line)
    end)
  end)
end)
