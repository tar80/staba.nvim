local M = {}

function M.setup(PLUGIN_NAME)
  local with_plugin_name = require('staba.util').name_formatter(PLUGIN_NAME)
  local cache = require('staba.cache')
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
    local bufnr = vim.api.nvim_get_current_buf()
    if not vim.bo[bufnr].buflisted then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    elseif #cache.buflist > 1 then
      pcall(vim.api.nvim_buf_delete, bufnr, { unload = false })
    else
      vim.cmd.close({ mods = { emsg_silent = true } })
    end
  end)

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
  end, { desc = with_plugin_name('[%s] unload buffer') })

  vim.keymap.set('n', '<Plug>(staba-cleanup)', function()
    local current_bufnr = vim.api.nvim_win_get_buf(0)
    vim.iter(vim.api.nvim_list_bufs()):each(function(bufnr)
      if vim.bo[bufnr].buftype ~= 'nofile' and not vim.bo[bufnr].modified and current_bufnr ~= bufnr then
        vim.api.nvim_buf_delete(bufnr, { unload = false })
      end
    end)
    vim.notify('Clean-up buffers', vim.log.levels.WARN, { title = 'staba.nvim' })
  end, { desc = with_plugin_name('[%s] clean-up buffers') })
end

return M
