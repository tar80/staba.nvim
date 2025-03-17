local M = {}

function M.setup(UNIQUE_NAME, opts, cache)
  local with_plugin_name = require('staba.util').name_formatter(UNIQUE_NAME)
  local lsp = require('staba.lsp')
  if opts.tabline then
    vim.keymap.set('n', '<Plug>(staba-pick)', function()
      local input = vim.fn.getcharstr(-1, { simplify = false })
      local bufnr = cache.buf_id[input:sub(-1):lower()]
      if not bufnr then
        return
      end
      if #input > 1 then
        if input:find('^') then
          vim.cmd('vertical sbuffer ' .. bufnr)
        end
      elseif input:match('%d') then
        vim.cmd.tabnext(input)
      elseif input:match('%u') then
        vim.cmd.sbuffer(bufnr)
      else
        vim.api.nvim_win_set_buf(0, bufnr)
      end
    end, { desc = with_plugin_name('[%s] pick a buffer') })

    vim.keymap.set('n', '<Plug>(staba-delete-current)', function()
      if not vim.api.nvim_get_option_value('buflisted', {}) then
        vim.api.nvim_buf_delete(0, { force = true })
      elseif #cache.buflist > 1 then
        local clients = lsp.buf_get_clients()
        if clients.count > 0 then
          lsp.buf_detach_clients(clients.ids)
        end
        pcall(vim.api.nvim_buf_delete, 0, { unload = false })
      else
        vim.cmd.close({ mods = { emsg_silent = true } })
      end
    end, { desc = with_plugin_name('[%s] unload current buffer') })

    vim.keymap.set('n', '<Plug>(staba-delete-select)', function()
      local input = vim.fn.getcharstr(-1, { simplify = true })
      local bufnr = cache.buf_id[input:sub(-1):lower()]
      if not bufnr then
        return
      end
      if input:match('%d') then
        vim.cmd.tabclose(input)
      else
        vim.api.nvim_buf_delete(bufnr, { unload = false })
      end
      vim.cmd.redrawtabline()
    end, { desc = with_plugin_name('[%s] unload select buffer') })

    vim.keymap.set('n', '<Plug>(staba-cleanup)', function()
      local current_bufnr = vim.api.nvim_win_get_buf(0)
      vim.iter(vim.api.nvim_list_bufs()):each(function(bufnr)
        if
          vim.api.nvim_get_option_value('buftype', { buf = bufnr }) ~= 'nofile'
          and not vim.api.nvim_get_option_value('modified', { buf = bufnr })
          and current_bufnr ~= bufnr
        then
          vim.api.nvim_buf_delete(bufnr, { unload = false })
        end
      end)
      vim.notify('Clean-up buffers', vim.log.levels.WARN, { title = 'staba.nvim' })
    end, { desc = with_plugin_name('[%s] clean-up buffers') })
  end

  if opts.enable_sign_marks then
    local function mark_update()
      vim.api.nvim_exec_autocmds('User', { pattern = 'StabaUpdateMark', modeline = false })
    end

    vim.keymap.set('n', '<Plug>(staba-mark-operator)', function()
      vim.schedule(function()
        mark_update()
      end)
      return 'm'
    end, { expr = true, desc = with_plugin_name('[%s] register mark') })

    vim.keymap.set('n', '<Plug>(staba-mark-delete)', function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local mark = cache.bufdata.mark[row]
      if mark then
        vim.api.nvim_buf_del_mark(0, mark.chr)
        vim.api.nvim_buf_del_extmark(0, cache.ns, mark.id)
        cache.bufdata.mark[row] = nil
      end
    end, { desc = with_plugin_name('[%s] delete mark') })

    vim.keymap.set('n', '<Plug>(staba-mark-delete-all)', function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      vim.iter(cache.bufdata.mark):each(function(t)
        vim.api.nvim_buf_del_mark(0, t.chr)
        cache.bufdata.mark[row] = nil
      end)
      cache.bufdata.mark = {}
      vim.api.nvim_buf_clear_namespace(0, cache.ns, 0, -1)
    end, { desc = with_plugin_name('[%s] delete mark') })

    vim.keymap.set('n', '<Plug>(staba-mark-toggle)', function()
      local row, col = unpack(vim.api.nvim_win_get_cursor(0))
      local mark = cache.bufdata.mark[row]
      if mark then
        vim.api.nvim_buf_del_mark(0, mark.chr)
        vim.api.nvim_buf_del_extmark(0, cache.ns, mark.id)
        cache.bufdata.mark[row] = nil
      else
        vim.api.nvim_buf_set_mark(0, 'm', row, col, {})
        mark_update()
      end
    end, { desc = with_plugin_name('[%s] toggle mark') })
  end
end

return M
