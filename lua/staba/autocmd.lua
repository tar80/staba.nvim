local M = {}
local cache = require('staba.cache')
local helper = require('staba.helper')

-- configure a single hlgroup for multiple hlgroups for winhighlight configuration
---@param mode_hl string[] To hlgroup names
---@param from string From hlgroup name
---@return string `value of winhighlight`
local function set_mode_hl(mode_hl, from)
  return vim
    .iter(mode_hl)
    :map(function(to)
      return to .. ':' .. from
    end)
    :join(',')
end

local function fade_background()
  vim.opt_local.winhighlight:append('NormalNC:StabaNC,StatuslineNC:StabaStatusNC')
end
local function non_fade_background()
  vim.api.nvim_win_call(cache.bufdata.winid, function()
    vim.opt_local.winhighlight:append('NormalNC:Normal,StatuslineNC:StabaStatus')
  end)
end

local function set_buffer_marks()
  local bufnr = cache.bufdata.actual_bufnr
  local marklist = vim.fn.getmarklist(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, cache.ns, 0, -1)
  vim.iter(marklist):each(function(t)
    if t.mark:find('%a') then
      local chr, row = t.mark:sub(-1), t.pos[2]
      local id = vim.api.nvim_buf_set_extmark(bufnr, cache.ns, row - 1, 0, {
        priority = 0,
        sign_text = chr,
        sign_hl_group = 'StabaSignMarks',
      })
      cache.bufdata.mark[row] = { chr = chr, id = id }
    end
  end)
end

---@param UNIQUE_NAME string
---@param opts Options
function M.setup(UNIQUE_NAME, opts)
  cache.ns = vim.api.nvim_create_namespace(UNIQUE_NAME)
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
          vim.opt_local.winhighlight:append(set_mode_hl(apply_hls, hlname))
        end
      end,
    })
  end

  if opts.enable_sign_marks then
    vim.api.nvim_create_autocmd('WinLeave', {
      desc = with_plugin_name('%s: remove marks'),
      group = augroup,
      callback = function()
        if not helper.is_floating_win(0) then
          vim.api.nvim_buf_clear_namespace(0, cache.ns, 0, -1)
        end
      end,
    })
    vim.api.nvim_create_autocmd('User', {
      desc = with_plugin_name('%s: update mark'),
      group = augroup,
      pattern = 'StabaUpdateMark',
      callback = function()
        set_buffer_marks()
      end,
    })
  end

  if opts.enable_fade then
    local fade_ignore = opts.ignore_filetypes.fade or {}
    --[[ NOTE:
    -- When Noice.nvim is loaded as a plugin, it initializes the Nui.nvim floating_window.
    -- However, this triggers unnecessary events. To avoid this, we are recreate the "BufWinEnter" autocmd.
    --]]
    local function _recreate_autocmd()
      vim.api.nvim_create_autocmd('BufWinEnter', {
        desc = with_plugin_name('%s: disable decorations'),
        group = augroup,
        callback = function(ev)
          if not helper.is_floating_win(0) then
            cache:set_bufdata(ev.buf)
          elseif opts.enable_fade then
            non_fade_background()
          end
        end,
      })
    end
    vim.api.nvim_create_autocmd('BufWinEnter', {
      desc = with_plugin_name('%s: disable decorations'),
      group = augroup,
      callback = function(ev)
        if package.loaded['noice'] then
          vim.api.nvim_del_autocmd(ev.id)
          _recreate_autocmd()
          return
        end
        if not helper.is_floating_win(0) then
          cache:set_bufdata(ev.buf)
        else
          non_fade_background()
        end
      end,
    })
    vim.api.nvim_create_autocmd('WinClosed', {
      desc = with_plugin_name('%s: reset alternate window highlights'),
      group = augroup,
      -- buffer = vim.api.nvim_get_current_buf(),
      callback = function(ev)
        if helper.is_floating_win(0) and ev.buf == vim.api.nvim_get_current_buf() then
          vim.api.nvim_win_call(cache.bufdata.winid, function()
            fade_background()
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
            if opts.enable_sign_marks then
              set_buffer_marks()
            end
            if not vim.list_contains(fade_ignore, vim.api.nvim_get_option_value('filetype', {})) then
              fade_background()
            end
          end)
        else
          if vim.fn.has('nvim-0.11') == 1 then
            -- NOTE: This is a setting to avoid registering winhighlight twice, but we need to be careful about side effects.
            vim.wo.eventignorewin = 'BufWinEnter'
          end
          non_fade_background()
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
          if opts.enable_sign_marks then
            vim.schedule(function()
              set_buffer_marks()
            end)
          end
        end
      end,
    })
  end

  if opts.statuscolumn then
    vim.api.nvim_create_autocmd('Filetype', {
      desc = with_plugin_name('%s: disable statuscolumn'),
      group = augroup,
      callback = function(ev)
        local ignore_filetypes = opts.ignore_filetypes
        if vim.list_contains(ignore_filetypes.statuscolumn, ev.match) then
          vim.api.nvim_set_option_value('statuscolumn', '', {})
          vim.api.nvim_set_option_value('signcolumn', 'auto', {})
        else
          vim.api.nvim_set_option_value('signcolumn', cache.signcolumn, {})
        end
      end,
    })
    vim.api.nvim_create_autocmd('OptionSet', {
      group = augroup,
      pattern = 'signcolumn',
      callback = function()
        cache.signcolumn = vim.api.nvim_get_option_value('signcolumn', { scope = 'global' })
      end,
    })

    if vim.list_contains(opts.statuscolumn, 'fold_ex') then
      vim.api.nvim_create_autocmd('OptionSet', {
        group = augroup,
        pattern = 'diff,foldcolumn',
        callback = function(ev)
          if ev.match == 'diff' then
            vim.api.nvim_set_option_value('foldcolumn', cache.foldcolumn, {})
          elseif ev.match == 'foldcolumn' then
            cache.foldcolumn = vim.api.nvim_get_option_value('foldcolumn', { scope = 'global' })
          end
        end,
      })
    end
  end

  vim.api.nvim_create_autocmd('BufAdd', {
    desc = with_plugin_name('%s: add listed buffer for tabline'),
    group = augroup,
    callback = function(ev)
      cache:add_to_buflist(ev.buf)
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
      if conf.set_hl_marks then
        conf.set_hl_marks()
      end
    end,
  })
end

return M
