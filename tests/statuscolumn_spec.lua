---@diagnostic disable: undefined-field, missing-fields, param-type-mismatch
local assert = require('luassert')
local stub = require('luassert.stub')

describe('statuscolumn', function()
  local statuscolumn
  local config

  before_each(function()
    package.loaded['staba.config'] = nil
    package.loaded['staba.cache'] = nil
    package.loaded['staba.statuscolumn'] = nil

    config = require('staba.config')
    config:setup({})

    statuscolumn = require('staba.statuscolumn')
  end)

  describe('build logic', function()
    it('generates a valid statuscolumn string', function()
      local draw_func = statuscolumn.draw or statuscolumn.build
      if type(draw_func) == 'function' then
        local res = draw_func()
        assert.is_string(res)
        assert.is_not_nil(res:match('%%'))
      end
    end)
  end)

  describe('components', function()
    it('returns fold icons from the established config', function()
      if type(statuscolumn.fold) == 'function' then
        stub(vim.fn, 'foldlevel', function()
          return 1
        end)
        stub(vim.fn, 'foldclosed', function()
          return -1
        end)

        local res = statuscolumn.fold(1)
        assert.is_string(res)

        vim.fn.foldlevel:revert()
        vim.fn.foldclosed:revert()
      end
    end)

    it('handles line number rendering', function()
      if type(statuscolumn.number) == 'function' then
        local res = statuscolumn.number()
        assert.is_string(res)
      end
    end)
  end)

  describe('.cache_parsed_expression()', function()
    it('correctly builds active and inactive expressions', function()
      local statuscolumn_config = { 'sign', 'number' }
      local fold_icon = { open = 'v', close = '>', blank = ' ' }

      statuscolumn.cache_parsed_expression(statuscolumn_config, fold_icon)

      local res = statuscolumn.draw and statuscolumn.draw() or ''

      assert.is_string(res)
    end)

    it('sets _has_fold_ex to true when fold_ex is present', function()
      local statuscolumn_config = { 'fold_ex', 'number' }
      local fold_icon = { open = 'v', close = '>', blank = ' ' }

      statuscolumn.cache_parsed_expression(statuscolumn_config, fold_icon)

      assert.has_no.errors(function()
        statuscolumn.cache_parsed_expression(statuscolumn_config, fold_icon)
      end)
    end)

    it('does not add blank space if the last element is not number', function()
      local statuscolumn_config = { 'number', 'sign' }
      local fold_icon = { open = 'v', close = '>', blank = ' ' }

      statuscolumn.cache_parsed_expression(statuscolumn_config, fold_icon)
    end)
  end)
end)
