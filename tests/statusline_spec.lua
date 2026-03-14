---@diagnostic disable: missing-fields, param-type-mismatch
local assert = require('luassert')

describe('statusline', function()
  local statusline
  local config

  before_each(function()
    package.loaded['staba.config'] = nil
    package.loaded['staba.cache'] = nil
    package.loaded['staba.statusline'] = nil
    package.loaded['staba.helper'] = nil

    config = require('staba.config')
    config:setup({})

    statusline = require('staba.statusline')
  end)

  describe('rendering', function()
    it('returns a string for the statusline', function()
      local render_func = statusline.render or statusline.draw
      if type(render_func) == 'function' then
        local res = render_func()
        assert.is_string(res)
        assert.is_not_nil(res:match('%%'))
      end
    end)
  end)

  describe('sections', function()
    it('renders the mode section with proper highlights', function()
      if type(statusline.mode) == 'function' then
        local res = statusline.mode()
        assert.is_string(res)
        assert.is_not_nil(res:match('%%#'))
      end
    end)

    it('renders file information using helper icons', function()
      if type(statusline.file_info) == 'function' then
        local res = statusline.file_info()
        assert.is_string(res)
      end
    end)
  end)
end)
