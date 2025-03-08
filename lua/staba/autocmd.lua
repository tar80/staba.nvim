local M = {}
local cache = require('staba.cache')
local helper = require('staba.helper')

local function _set_mode_hl(mode_hl, from)
  return vim
    .iter(mode_hl)
    :map(function(to)
      return to .. ':' .. from
    end)
    :join(',')
end

---@param UNIQUE_NAME string
---@param opts Options
function M.setup(UNIQUE_NAME, opts)
  local augroup = vim.api.nvim_create_augroup(UNIQUE_NAME, { clear = true })
  local with_plugin_name = require('staba.util').name_formatter(UNIQUE_NAME)
  local rgx_mode = ':([ictsrv\x16])'

  if opts.mode_line then
    local apply_hls = opts.mode_line == 'CursorLine' and { 'CursorLine' } or { 'LineNr', 'CursorLineNr' }
    local mode_tbl = {
      i = opts.hlnames.mode_i,
      s = opts.hlnames.mode_s,
      r = opts.hlnames.mode_r,
      c = opts.hlnames.mode_c,
      t = opts.hlnames.mode_c,
      v = opts.hlnames.mode_v,
      ['\x16'] = opts.hlnames.mode_vb,
    }
    vim.api.nvim_create_autocmd('ModeChanged', {
      desc = with_plugin_name('%s: mode LineNr'),
      group = augroup,
      callback = function(ev)
        local mode = ev.match:lower():match(rgx_mode)
        if mode == 'i' and vim.v.insertmode ~= 'i' then
          mode = 'r'
        end
        local hlname = mode_tbl[mode]
        cache.mode = mode

        if not hlname then
          vim.opt_local.winhighlight:remove(apply_hls)
        else
          vim.opt_local.winhighlight:append(_set_mode_hl(apply_hls, hlname))
        end
      end,
    })
  end

  if opts.enable_fade then
    local fade_ignore = opts.ignore_filetypes.fade or {}
    vim.api.nvim_create_autocmd('WinClosed', {
      desc = with_plugin_name('%s: reset alternate window highlights'),
      group = augroup,
      -- buffer = vim.api.nvim_get_current_buf(),
      callback = function(ev)
        if helper.is_floating_win(0) and ev.buf == vim.api.nvim_get_current_buf() then
          vim.api.nvim_win_call(cache.bufdata.winid, function()
            vim.opt_local.winhighlight:append('NormalNC:StabaNC,StatuslineNC:StabaStatusNC')
          end)
        end
      end,
    })
    vim.api.nvim_create_autocmd('WinEnter', {
      desc = with_plugin_name('%s: set window highlights'),
      group = augroup,
      callback = function(ev)
        if not helper.is_floating_win(0) then
          cache:set_bufdata(ev.buf)
          vim.schedule(function()
            if not vim.list_contains(fade_ignore, vim.api.nvim_get_option_value('filetype', {})) then
              vim.opt_local.winhighlight:append('NormalNC:StabaNC,StatuslineNC:StabaStatusNC')
            end
          end)
        else
          vim.api.nvim_win_call(cache.bufdata.winid, function()
            vim.opt_local.winhighlight:append('NormalNC:Normal,StatuslineNC:StabaStatus')
          end)
        end
      end,
    })
  else
    vim.api.nvim_create_autocmd('WinEnter', {
      desc = with_plugin_name('%s: set window highlights'),
      group = augroup,
      callback = function(ev)
        if not helper.is_floating_win(0) then
          cache:set_bufdata(ev.buf)
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd('BufAdd', {
    desc = with_plugin_name('%s: add listed buffer for tabline'),
    group = augroup,
    callback = function(ev)
      cache:add_to_buflist(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    desc = with_plugin_name('%s: disable decorations'),
    group = augroup,
    callback = function(ev)
      if not helper.is_floating_win(0) then
        cache:set_bufdata(ev.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('Filetype', {
    desc = with_plugin_name('%s: disable statuscolumn'),
    group = augroup,
    callback = function(ev)
      local ignore_filetypes = opts.ignore_filetypes
      if vim.list_contains(ignore_filetypes.statuscolumn, ev.match) then
        vim.api.nvim_set_option_value('statuscolumn', '', {})
        vim.api.nvim_set_option_value('signcolumn', 'auto', {})
      end
    end,
  })
  vim.api.nvim_create_autocmd('ColorScheme', {
    desc = with_plugin_name('%s: get set hlgroups'),
    group = augroup,
    callback = function(_)
      local conf = require('staba.config')
      if conf.set_hl_fade then
        conf.set_hl_fade()
      end
      if conf.set_hl_mode then
        local mode_line = cache:get('bufdata').mode_line
        conf.set_hl_mode(mode_line)
      end
      if conf.set_hl_tab then
        conf.set_hl_tab(opts.enable_underline)
      end
      if conf.set_hl_status then
        conf.set_hl_status(opts.enable_underline)
      end
    end,
  })
end

return M
