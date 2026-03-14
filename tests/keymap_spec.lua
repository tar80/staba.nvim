---@diagnostic disable: undefined-field
local assert = require('luassert')
local stub = require('luassert.stub')

describe('keymap', function()
  describe('<Plug>(staba-pick)', function()
    local keymap
    local mock_cache
    local mock_opts = { tabline = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        buf_id = {
          ['a'] = 10,
          ['b'] = 20,
          ['1'] = 1,
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.fn, 'getcharstr')
      stub(vim.cmd, 'sbuffer')
      stub(vim.cmd, 'vertical')
      stub(vim.cmd, 'tabnext')
      stub(vim.api, 'nvim_win_set_buf')
    end)

    after_each(function()
      vim.fn.getcharstr:revert()
      vim.cmd.sbuffer:revert()
      vim.cmd.vertical:revert()
      vim.cmd.tabnext:revert()
      vim.api.nvim_win_set_buf:revert()
    end)

    local function trigger_pick()
      local map = vim.fn.maparg('<Plug>(staba-pick)', 'n', false, true)
      map.callback()
    end

    it('switches buffer when a lowercase key is pressed', function()
      vim.fn.getcharstr.returns('a')

      trigger_pick()

      assert.stub(vim.api.nvim_win_set_buf).was_called_with(0, 10)
    end)

    it('opens sbuffer when an uppercase key is pressed', function()
      vim.fn.getcharstr.returns('A')

      trigger_pick()

      assert.stub(vim.cmd.sbuffer).was_called_with(10)
    end)

    it('switches tabs when a number key is pressed', function()
      vim.fn.getcharstr.returns('1')

      trigger_pick()

      assert.stub(vim.cmd.tabnext).was_called_with('1')
    end)

    it('does nothing if the input key is not in cache.buf_id', function()
      vim.fn.getcharstr.returns('z')

      trigger_pick()

      assert.stub(vim.api.nvim_win_set_buf).was_not_called()
      assert.stub(vim.cmd.sbuffer).was_not_called()
    end)

    it('performs vertical split and switches buffer when Ctrl-a is pressed', function()
      local bufnr = vim.api.nvim_create_buf(true, true)
      vim.api.nvim_buf_set_name(bufnr, 'test_buffer_a')
      mock_cache = {
        buf_id = {
          ['a'] = bufnr,
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      assert.are.equal(1, #vim.api.nvim_list_wins())
      local getchar_stub = require('luassert.stub')(vim.fn, 'getcharstr')
      getchar_stub.returns(string.char(1))

      local map = vim.fn.maparg('<Plug>(staba-pick)', 'n', false, true)
      map.callback()

      local wins = vim.api.nvim_list_wins()
      assert.are.equal(2, #wins, 'Should have opened a new window via split')

      local pos1 = vim.api.nvim_win_get_position(wins[1])
      local pos2 = vim.api.nvim_win_get_position(wins[2])
      assert.are.equal(pos1[1], pos2[1], 'Windows should be on the same row (vertical split)')
      assert.is_not.equal(pos1[2], pos2[2], 'Windows should be on different columns')

      local current_buf = vim.api.nvim_get_current_buf()
      assert.are.equal(mock_cache.buf_id['a'], current_buf)

      getchar_stub:revert()
      vim.cmd('silent! only')
      vim.cmd('silent! bwipeout!')
    end)
  end)

  describe('<Plug>(staba-delete-current)', function()
    local keymap
    local mock_cache
    local mock_opts = { tabline = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        buflist = { 1, 2 },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.api, 'nvim_buf_delete')
      stub(vim.cmd, 'close')
      stub(vim.api, 'nvim_get_option_value')
    end)

    after_each(function()
      vim.api.nvim_buf_delete:revert()
      vim.cmd.close:revert()
      vim.api.nvim_get_option_value:revert()
    end)

    local function trigger_delete()
      local map = vim.fn.maparg('<Plug>(staba-delete-current)', 'n', false, true)
      map.callback()
    end

    it('deletes with force if buffer is not buflisted', function()
      vim.api.nvim_get_option_value.returns(false)

      trigger_delete()

      assert.stub(vim.api.nvim_buf_delete).was_called_with(0, { force = true })
    end)

    it('unloads buffer if more than one buffer exists in buflist', function()
      vim.api.nvim_get_option_value.returns(true)
      mock_cache.buflist = { 1, 2 }

      trigger_delete()

      assert.stub(vim.api.nvim_buf_delete).was_called_with(0, { unload = false })
    end)

    it('closes the window if it is the last buffer', function()
      vim.api.nvim_get_option_value.returns(true)
      mock_cache.buflist = { 1 }

      trigger_delete()

      assert.stub(vim.cmd.close).was_called_with({ mods = { emsg_silent = true } })
    end)
  end)

  describe('<Plug>(staba-delete-select)', function()
    local keymap
    local mock_cache
    local mock_opts = { tabline = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        buf_id = {
          ['a'] = 105,
          ['b'] = 106,
          ['1'] = 1,
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.fn, 'getcharstr')
      stub(vim.api, 'nvim_buf_delete')
      stub(vim.cmd, 'tabclose')
      stub(vim.cmd, 'redrawtabline')
    end)

    after_each(function()
      vim.fn.getcharstr:revert()
      vim.api.nvim_buf_delete:revert()
      vim.cmd.tabclose:revert()
      vim.cmd.redrawtabline:revert()
    end)

    local function trigger_delete_select()
      local map = vim.fn.maparg('<Plug>(staba-delete-select)', 'n', false, true)
      map.callback()
    end

    it('deletes a specific buffer when a character key is pressed', function()
      vim.fn.getcharstr.returns('a')

      trigger_delete_select()

      assert.stub(vim.api.nvim_buf_delete).was_called_with(105, { unload = false })
      assert.stub(vim.cmd.redrawtabline).was_called()
    end)

    it('closes a tab when a number key is pressed', function()
      vim.fn.getcharstr.returns('1')

      trigger_delete_select()

      assert.stub(vim.cmd.tabclose).was_called_with('1')
      assert.stub(vim.cmd.redrawtabline).was_called()
    end)

    it('does nothing if the input is not in cache', function()
      vim.fn.getcharstr.returns('z')

      trigger_delete_select()

      assert.stub(vim.api.nvim_buf_delete).was_not_called()
      assert.stub(vim.cmd.tabclose).was_not_called()
      assert.stub(vim.cmd.redrawtabline).was_not_called()
    end)
  end)

  describe('<Plug>(staba-mark-operator)', function()
    local keymap
    local mock_opts = { enable_sign_marks = true }
    local mock_cache = {
      bufdata = { mark = {} },
      ns = 100,
    }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')

      stub(vim.api, 'nvim_exec_autocmds')
      stub(vim, 'schedule', function(fn)
        fn()
      end)

      keymap.setup('staba', mock_opts, mock_cache)
    end)

    after_each(function()
      vim.api.nvim_exec_autocmds:revert()
      vim.schedule:revert()
    end)

    it('returns "m" to trigger the native mark operator', function()
      local map = vim.fn.maparg('<Plug>(staba-mark-operator)', 'n', false, true)

      local res = map.callback()
      assert.are.equal('m', res)
    end)

    it('triggers StabaUpdateMark User autocmd', function()
      local map = vim.fn.maparg('<Plug>(staba-mark-operator)', 'n', false, true)

      map.callback()

      assert.stub(vim.api.nvim_exec_autocmds).was_called_with('User', {
        pattern = 'StabaUpdateMark',
        modeline = false,
      })
    end)
  end)

  describe('<Plug>(staba-mark-delete)', function()
    local keymap
    local mock_cache
    local mock_opts = { enable_sign_marks = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        ns = 50,
        bufdata = {
          mark = {
            [10] = { chr = 'a', id = 1001 },
          },
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.api, 'nvim_win_get_cursor')
      stub(vim.api, 'nvim_buf_del_mark')
      stub(vim.api, 'nvim_buf_del_extmark')
    end)

    after_each(function()
      vim.api.nvim_win_get_cursor:revert()
      vim.api.nvim_buf_del_mark:revert()
      vim.api.nvim_buf_del_extmark:revert()
    end)

    local function trigger_mark_delete()
      local map = vim.fn.maparg('<Plug>(staba-mark-delete)', 'n', false, true)
      map.callback()
    end

    it('deletes mark and extmark if they exist on the current line', function()
      vim.api.nvim_win_get_cursor.returns({ 10, 0 })

      trigger_mark_delete()

      assert.stub(vim.api.nvim_buf_del_mark).was_called_with(0, 'a')
      assert.stub(vim.api.nvim_buf_del_extmark).was_called_with(0, 50, 1001)
      assert.is_nil(mock_cache.bufdata.mark[10])
    end)

    it('does nothing if no mark exists on the current line', function()
      vim.api.nvim_win_get_cursor.returns({ 20, 0 })

      trigger_mark_delete()

      assert.stub(vim.api.nvim_buf_del_mark).was_not_called()
      assert.stub(vim.api.nvim_buf_del_extmark).was_not_called()
      assert.is_not_nil(mock_cache.bufdata.mark[10])
    end)
  end)

  describe('<Plug>(staba-mark-delete-all)', function()
    local keymap
    local mock_cache
    local mock_opts = { enable_sign_marks = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        ns = 50,
        bufdata = {
          mark = {
            [5] = { chr = 'a', id = 100 },
            [10] = { chr = 'b', id = 101 },
            [15] = { chr = 'c', id = 102 },
          },
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.api, 'nvim_win_get_cursor', function()
        return { 10, 0 }
      end)
      stub(vim.api, 'nvim_buf_del_mark')
      stub(vim.api, 'nvim_buf_clear_namespace')
    end)

    after_each(function()
      vim.api.nvim_win_get_cursor:revert()
      vim.api.nvim_buf_del_mark:revert()
      vim.api.nvim_buf_clear_namespace:revert()
    end)

    local function trigger_delete_all()
      local map = vim.fn.maparg('<Plug>(staba-mark-delete-all)', 'n', false, true)
      map.callback()
    end

    it('deletes all marks in the cache and clears the namespace', function()
      trigger_delete_all()

      assert.stub(vim.api.nvim_buf_del_mark).was_called_with(0, 'a')
      assert.stub(vim.api.nvim_buf_del_mark).was_called_with(0, 'b')
      assert.stub(vim.api.nvim_buf_del_mark).was_called_with(0, 'c')
      assert.stub(vim.api.nvim_buf_del_mark).was_called(3)
      assert.stub(vim.api.nvim_buf_clear_namespace).was_called_with(0, 50, 0, -1)
      assert.are.same({}, mock_cache.bufdata.mark)
    end)
  end)

  describe('<Plug>(staba-mark-toggle)', function()
    local keymap
    local mock_cache
    local mock_opts = { enable_sign_marks = true }

    before_each(function()
      package.loaded['staba.keymap'] = nil
      keymap = require('staba.keymap')
      mock_cache = {
        ns = 50,
        bufdata = {
          mark = {
            [10] = { chr = 'm', id = 500 },
          },
        },
      }

      keymap.setup('staba', mock_opts, mock_cache)

      stub(vim.api, 'nvim_win_get_cursor')
      stub(vim.api, 'nvim_buf_set_mark')
      stub(vim.api, 'nvim_buf_del_mark')
      stub(vim.api, 'nvim_buf_del_extmark')
      stub(vim.api, 'nvim_exec_autocmds')
      stub(vim, 'schedule', function(fn)
        fn()
      end)
    end)

    after_each(function()
      vim.api.nvim_win_get_cursor:revert()
      vim.api.nvim_buf_set_mark:revert()
      vim.api.nvim_buf_del_mark:revert()
      vim.api.nvim_buf_del_extmark:revert()
      vim.api.nvim_exec_autocmds:revert()
      vim.schedule:revert()
    end)

    local function trigger_toggle()
      local map = vim.fn.maparg('<Plug>(staba-mark-toggle)', 'n', false, true)
      map.callback()
    end

    it('deletes the mark if it already exists on the current line', function()
      vim.api.nvim_win_get_cursor.returns({ 10, 0 })

      trigger_toggle()

      assert.stub(vim.api.nvim_buf_del_mark).was_called_with(0, 'm')
      assert.stub(vim.api.nvim_buf_del_extmark).was_called_with(0, 50, 500)
      assert.stub(vim.api.nvim_buf_set_mark).was_not_called()
      assert.is_nil(mock_cache.bufdata.mark[10])
    end)

    it('sets a new mark and triggers update if no mark exists on the line', function()
      vim.api.nvim_win_get_cursor.returns({ 20, 5 })

      trigger_toggle()

      assert.stub(vim.api.nvim_buf_set_mark).was_called_with(0, 'm', 20, 5, {})
      assert.stub(vim.api.nvim_exec_autocmds).was_called_with('User', {
        pattern = 'StabaUpdateMark',
        modeline = false,
      })
    end)
  end)
end)
