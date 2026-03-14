local assert = require('luassert')

describe('staba.wrap_no_fade_background()', function()
  local staba

  before_each(function()
    package.loaded['staba'] = nil
    staba = require('staba')
  end)

  it('applies temporary winhighlight during function execution', function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local winid = vim.api.nvim_open_win(bufnr, true, {
      relative = 'editor',
      width = 10,
      height = 10,
      row = 1,
      col = 1,
    })

    local captured_hl = ''
    local test_func = function(arg1)
      captured_hl = vim.wo[winid].winhighlight
      return arg1
    end

    local result = staba.wrap_no_fade_background(test_func, 'hello')

    assert.are.equal('hello', result)
    assert.is_not_nil(captured_hl:match('NormalNC:Normal'))
    assert.is_not_nil(captured_hl:match('StatuslineNC:StabaStatus'))
    assert.are.equal(captured_hl, vim.wo[winid].winhighlight)
    vim.api.nvim_win_close(winid, true)
  end)

  it('manages winhighlight independently for different buffers', function()
    local win_a = vim.api.nvim_get_current_win()
    vim.wo[win_a].winhighlight = 'Normal:MyGroup'

    local buf_b = vim.api.nvim_create_buf(false, true)
    local win_b = vim.api.nvim_open_win(buf_b, false, {
      relative = 'editor',
      width = 10,
      height = 10,
      row = 5,
      col = 5,
    })

    local initial_hl_b = vim.wo[win_b].winhighlight

    vim.api.nvim_set_current_win(win_a)
    staba.wrap_no_fade_background(function()
      assert.is_not_nil(vim.wo[win_a].winhighlight:match('NormalNC:Normal'))
      assert.are.equal(
        initial_hl_b,
        vim.wo[win_b].winhighlight,
        'Window B should not be affected by changes in Window A'
      )
      assert.is_nil(vim.wo[win_b].winhighlight:match('NormalNC:Normal'))
    end)

    vim.api.nvim_win_close(win_b, true)
  end)

  it('applies winhighlight correctly even when focus is on a floating window', function()
    local f_buf = vim.api.nvim_create_buf(false, true)
    local f_win = vim.api.nvim_open_win(f_buf, true, {
      relative = 'editor',
      width = 20,
      height = 5,
      row = 2,
      col = 2,
      border = 'single',
    })

    local initial_f_hl = vim.wo[f_win].winhighlight

    staba.wrap_no_fade_background(function()
      local current_hl = vim.wo[f_win].winhighlight

      assert.is_not_nil(current_hl:match('NormalNC:Normal'), 'Floating window should have NormalNC set to Normal')
      assert.is_not_nil(
        current_hl:match('StatuslineNC:StabaStatus'),
        'Floating window should have StatuslineNC set to StabaStatus'
      )

      if initial_f_hl ~= '' then
        assert.is_not_nil(current_hl:match(initial_f_hl), 'Original floating window highlights should be preserved')
      end
    end)

    vim.api.nvim_win_close(f_win, true)
  end)

  it('preserves existing winhighlight while appending new ones', function()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = 10,
      height = 5,
      row = 1,
      col = 1,
    })

    local existing = 'NormalFloat:MyCustomFloat,FloatBorder:MyBorder'
    vim.wo[win].winhighlight = existing

    staba.wrap_no_fade_background(function()
      local current = vim.wo[win].winhighlight
      assert.is_not_nil(current:match('NormalFloat:MyCustomFloat'))
      assert.is_not_nil(current:match('FloatBorder:MyBorder'))
      assert.is_not_nil(current:match('NormalNC:Normal'))
    end)

    vim.api.nvim_win_close(win, true)
  end)

  it('does not crash if the function returns nil or a complex table', function()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = 10,
      height = 5,
      row = 1,
      col = 1,
    })

    local expected_table = { status = 'ok', code = 200 }
    local result = staba.wrap_no_fade_background(function()
      return expected_table
    end)

    assert.are.same(expected_table, result)
    vim.api.nvim_win_close(win, true)
  end)
end)
