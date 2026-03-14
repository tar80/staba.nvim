---@diagnostic disable: undefined-field
local assert = require('luassert')
local stub = require('luassert.stub')

describe('cache', function()
  local cache

  before_each(function()
    package.loaded['staba.cache'] = nil
    cache = require('staba.cache')
  end)

  describe('.new()', function()
    it('should initialize state on the instance itself', function()
      local mock_opts = {
        hlnames = { test = 'HL' },
        icons = { status = { copilot = { 'C', 'Hl' } } },
        ignore_filetypes = { 'NvimTree' },
        frame = {},
        sep = {},
      }

      cache:new(mock_opts)

      assert.are.same(mock_opts.ignore_filetypes, cache.ignore_filetypes)
      assert.is_table(cache.bufs)
      assert.is_table(cache.buflist)
    end)
  end)

  describe(':remove()', function()
    it('should remove specific values from internal lists', function()
      cache:new({ hlnames = {}, icons = {}, ignore_filetypes = {}, frame = {}, sep = {} })
      cache.buflist = { 1, 2, 3, 4 }
      cache:remove('buflist', 3)

      assert.are.same({ 1, 2, 4 }, cache.buflist)
    end)
  end)

  describe('Buffer Management', function()
    local mock_opts = {
      hlnames = {},
      icons = {},
      ignore_filetypes = {},
      frame = {},
      sep = {},
    }

    before_each(function()
      cache:new(mock_opts)
    end)

    it('should add buffer to buflist and initialize bufs entry', function()
      local bufnr = 42
      local test_name = '/tmp/test.lua'
      local s = stub(vim.api, 'nvim_buf_get_name')
      s.on_call_with(bufnr).returns(test_name)
      cache:add_to_buflist(bufnr)

      assert.is_true(vim.list_contains(cache.buflist, bufnr))
      assert.are.equal(test_name, cache.bufs[bufnr].name)
      assert.is_table(cache.bufs[bufnr].devicon)

      s:revert()
    end)

    it('should set bufdata with current context', function()
      local bufnr = 10
      local test_path = '/home/user/project/file.lua'
      stub(vim.api, 'nvim_buf_get_name').returns(test_path)
      stub(vim.api, 'nvim_tabpage_get_win').returns(1001)
      stub(vim.fn, 'bufnr').returns(9)
      cache:set_bufdata(bufnr)

      assert.are.equal('/home/user/project', cache.bufdata.cwd)
      assert.are.equal(1001, cache.bufdata.winid)
      assert.are.equal(bufnr, cache.bufdata.actual_bufnr)

      vim.api.nvim_buf_get_name:revert()
      vim.api.nvim_tabpage_get_win:revert()
      vim.fn.bufnr:revert()
    end)
  end)

  describe('Helper logic (expand_icon)', function()
    it('should expand icon table with highlight strings', function()
      local mock_opts = {
        icons = {
          test_icon = { { 'X', 'MyHl' } },
        },
        hlnames = {},
        ignore_filetypes = {},
        frame = {},
        sep = {},
      }

      cache:new(mock_opts)

      assert.are.equal('%#MyHl#X', cache.icons.test_icon[1])
    end)

    it('should handle various data structures in expand_icon', function()
      local complex_icons = {
        simple = 'IconA',
        with_hl = { 'IconB', 'HlB' },
        nested = {
          sub = { 'IconC', 'HlC' },
        },
      }
      cache:new({ icons = complex_icons, hlnames = {}, ignore_filetypes = {}, frame = {}, sep = {} })

      assert.are.equal('IconA', cache.icons.simple)
      assert.are.equal('%#HlB#IconB', cache.icons.with_hl)
      assert.are.equal('%#HlC#IconC', cache.icons.nested.sub)
    end)

    it('should fallback to nvim-web-devicons if mini.icons is missing', function()
      package.loaded['mini.icons'] = nil
      local devicons_mock = {
        get_icon_by_filetype = function()
          return '󰉋', 'DevIconLua'
        end,
      }
      package.loaded['nvim-web-devicons'] = devicons_mock

      local s_name = stub(vim.api, 'nvim_buf_get_name').returns('test.lua')
      cache:new({ icons = {}, hlnames = {}, ignore_filetypes = {}, frame = {}, sep = {} })

      local bufnr = 10
      cache:add_to_buflist(bufnr)
      cache:set_to_buficon(bufnr, 'lua')

      assert.are.equal('󰉋', cache.bufs[bufnr].devicon.chr)
      assert.are.equal('DevIconLua', cache.bufs[bufnr].devicon.hlgroup)

      s_name:revert()
    end)
  end)
end)
