local M = {}
local helper = require('staba.helper')
local icon = require('staba.icon')
local ui = require('staba.icon.ui')
local validate = require('staba.compat').validate
local frame = ui.frame
local sep = ui.sep

local HL_NAMES = {
  -- mode
  mode_i = 'StabaInsertMode',
  mode_v = 'StabaVisualMode',
  mode_s = 'StabaSelectMode',
  mode_r = 'StabaReplaceMode',
  mode_c = 'StabaCmdlineMode',

  -- none current
  nc = 'StabaNC',

  -- statusline
  status = 'StabaStatus',
  status_nc = 'StabaStatusNC',
  status_reverse = 'StabaStatusReverse',

  -- tabline
  tabfill_reverse = 'StabaTabFillReverse',
  tabs = 'StabaTabs',
  tabs_reverse = 'StabaTabsReverse',
  buffers = 'StabaBuffers',
  buffers_reverse = 'StabaBuffersReverse',

  special = 'StabaSpecial',
  readonly = 'StabaReadonly',
  modified = 'StabaModified',
}
local HL_DETAILS = {
  mode_i = { fg = 'Cyan' },
  mode_v = { fg = 'Blue' },
  mode_s = { fg = 'Magenta' },
  mode_r = { fg = 'Magenta' },
  mode_c = { fg = 'NONE' },
}

---@param item {chr:string?,hl:string?,prefix:string?,suffix:string?}
---@return string
local function separator(item)
  if item.chr then
    local hl = item.hl and '%#' .. item.hl .. '#' or ''
    local prefix = item.prefix and item.prefix or ''
    local suffix = item.suffix and item.suffix or ''
    return prefix .. hl .. item.chr .. suffix
  end
  return ''
end

local DEFAULT_NO_NAME = '[No Name]'
local DEFAULT_NAV_KEYS = 'asdfghjklzxcvnmweryuiop'
local DEFAULT_FRAME = {
  tabs_left = separator({ chr = frame.slant_d.left, hl = HL_NAMES.tabs_reverse }),
  tabs_right = separator({ chr = frame.bar.right, hl = HL_NAMES.tabs_reverse }),
  buffers_left = separator({ chr = frame.slant_d.left, hl = HL_NAMES.buffers_reverse }),
  buffers_right = separator({ chr = frame.bar.right, hl = HL_NAMES.buffers_reverse }),
  statusline_left = separator({ chr = frame.slant_u.left, hl = HL_NAMES.status_reverse }),
  statusline_right = separator({ chr = frame.slant_u.right, hl = HL_NAMES.status_reverse }),
}
local DEFAULT_SEP = {
  normal_left = separator({ chr = sep.arrow.left, hl = 'TablineFill', suffix = '%* ' }),
  normal_right = separator({ chr = sep.arrow.right, hl = 'TablineFill', suffix = '%* ' }),
}
local DEFAULT_STATUSCOLUMN = { 'sign', 'number', 'fold_ex' }
local DEFAULT_STATUSLINE = {
  active = {
    left = { 'staba_logo', 'search_count', 'noice_mode' },
    middle = {},
    right = { '%<', 'diagnostics', ' ', 'encoding', ' ', 'position' },
  },
  inactive = { left = {}, middle = { 'devicon', 'filename', '%*' }, right = {} },
}
local DEFAULT_TABLINE = {
  left = { 'bufinfo', 'parent', 'shellslash', ' ' },
  view = { 'buffers', 'tabs' },
  right = {},
  bufinfo = {
    '%#StabaTabsReverse#',
    'tab',
    '%#StabaBuffersReverse#',
    'buffer',
    '%#StabaModified#',
    'modified',
    '%#StabaSpecial#',
    'unopened',
    '%* ',
  },
  active = { 'devicon', 'namestate' },
}

local DEFAULT_IGNORE = {
  statuscolumn = { 'qf', 'help', 'terminal' },
  statusline = { 'terminal' },
}

local function _set_tabline_tabs(frame_spec)
  return { frame_spec.tabs_left, '%#StabaTabs#', 'nav_key', frame_spec.tabs_right, 'namestate' }
end

local function _set_tabline_buffers(frame_spec)
  return { frame_spec.buffers_left, '%#StabaBuffers#', 'nav_key', frame_spec.buffers_right, 'namestate' }
end

local function _set_hl_fade()
  local hlgroups = {}
  --NOTE: dark = #222222, light = #DDDDDD
  local default_fade = vim.go.background == 'dark' and 2236962 or 14540253
  local normal_nc = vim.api.nvim_get_hl(0, { name = 'NormalNC', create = false })
  local staba_nc = vim.api.nvim_get_hl(0, { name = HL_NAMES.nc, create = false })
  local win_sep = vim.api.nvim_get_hl(0, { name = 'WinSeparator', create = false })
  local fade_bg = staba_nc.bg or default_fade
  --NOTE: Whether the separator background should be faded.
  -- vim.api.nvim_set_hl(0, 'WinSeparator', { fg = win_sep.fg, bg = fade_bg })
  hlgroups[HL_NAMES.nc] = { bg = fade_bg }
  hlgroups[HL_NAMES.status_nc] = { fg = normal_nc.fg, bg = fade_bg, sp = win_sep.fg, underline = true, italic = true }
  helper.set_hl(hlgroups)
end

---@param mode_line lineNr
local function _set_hl_mode(mode_line)
  local hlgroups = {}
  local linenr = vim.api.nvim_get_hl(0, { name = mode_line, create = false })
  local options = { bold = linenr.bold, italic = linenr.italic }
  hlgroups[HL_NAMES.mode_i] = vim.tbl_extend('keep', HL_DETAILS.mode_i, options)
  hlgroups[HL_NAMES.mode_v] = vim.tbl_extend('keep', HL_DETAILS.mode_v, options)
  hlgroups[HL_NAMES.mode_s] = vim.tbl_extend('keep', HL_DETAILS.mode_s, options)
  hlgroups[HL_NAMES.mode_r] = vim.tbl_extend('keep', HL_DETAILS.mode_r, options)
  hlgroups[HL_NAMES.mode_c] = vim.tbl_extend('keep', HL_DETAILS.mode_c, options)
  helper.set_hl(hlgroups)
end

---@param enable_underline boolean
local function _set_hl_tab(enable_underline)
  local hlgroups = {}
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal', create = false })
  local tab_fill = vim.api.nvim_get_hl(0, { name = 'TabLineFill', create = false })
  local win_sep = vim.api.nvim_get_hl(0, { name = 'WinSeparator', create = false })
  vim.api.nvim_set_hl(
    0,
    'TabLineFill',
    { fg = tab_fill.fg, bg = tab_fill.bg, sp = win_sep.fg, underline = enable_underline }
  )
  hlgroups[HL_NAMES.tabfill_reverse] = { fg = tab_fill.bg, bg = tab_fill.fg }
  hlgroups[HL_NAMES.tabs] = { fg = normal.bg, bg = 'SlateBlue', sp = 'SlateBlue' }
  hlgroups[HL_NAMES.tabs_reverse] = { fg = 'SlateBlue', bg = tab_fill.bg }
  hlgroups[HL_NAMES.buffers] = { fg = normal.bg, bg = 'Gray', sp = 'Gray' }
  hlgroups[HL_NAMES.buffers_reverse] = { fg = 'Gray', bg = tab_fill.bg }
  hlgroups[HL_NAMES.special] = { fg = 'Violet', sp = win_sep.fg }
  hlgroups[HL_NAMES.readonly] = { fg = 'Gray', sp = win_sep.fg }
  hlgroups[HL_NAMES.modified] = { fg = 'Cyan', sp = win_sep.fg }
  helper.set_hl(hlgroups)
end

---@param enable_underline boolean
local function _set_hl_status(enable_underline)
  local hlgroups = {}
  local normal_nc = vim.api.nvim_get_hl(0, { name = 'NormalNC', create = false })
  local statusline = vim.api.nvim_get_hl(0, { name = 'StatusLine', create = false })
  local win_sep = vim.api.nvim_get_hl(0, { name = 'WinSeparator', create = false })
  vim.api.nvim_set_hl(
    0,
    'StatusLine',
    { fg = statusline.fg, bg = statusline.bg, sp = win_sep.fg, underline = enable_underline }
  )
  vim.api.nvim_set_hl(
    0,
    'StatusLineNC',
    { fg = normal_nc.fg, bg = normal_nc.bg, sp = win_sep.fg, underline = enable_underline }
  )
  hlgroups[HL_NAMES.status] = { fg = statusline.fg, bg = statusline.bg, sp = win_sep.fg, underline = enable_underline }
  hlgroups[HL_NAMES.status_reverse] = { fg = statusline.bg, bg = statusline.fg, sp = win_sep.fg }
  helper.set_hl(hlgroups)
end

---@param user_spec UserSpec
---@return Options
function M.setup(user_spec)
  validate('enable_fade', user_spec.enable_fade, 'boolean', true)
  validate('enable_underline', user_spec.enable_underline, 'boolean', true)
  validate('mode_line', user_spec.mode_line, 'string', true)
  validate('nav_keys', user_spec.nav_keys, 'string', true)
  validate('no_name', user_spec.no_name, 'string', true)
  validate('ignore_filetypes', user_spec.ignore_filetypes, 'table', true)
  validate('statuscolumn', user_spec.statuscolumn, 'table', true)
  validate('statusline', user_spec.statusline, 'table', true)
  validate('tabline', user_spec.tabline, 'table', true)
  validate('frame', user_spec.frame, 'table', true)
  validate('sep', user_spec.sep, 'table', true)
  validate('icons', user_spec.icons, 'table', true)

  local opts = {}
  opts.hlnames = HL_NAMES
  opts.nav_keys = user_spec.nav_keys or DEFAULT_NAV_KEYS
  opts.mode_line = (type(user_spec.mode_line) == 'string' and ('CursorLineNr'):find(user_spec.mode_line, 1, true))
      and user_spec.mode_line
    or nil
  opts.no_name = user_spec.no_name or DEFAULT_NO_NAME
  opts.ignore_filetypes = vim.tbl_deep_extend('force', DEFAULT_IGNORE, user_spec.ignore_filetypes or {})
  opts.frame = vim.tbl_deep_extend('force', DEFAULT_FRAME, user_spec.frame or {})
  opts.sep = vim.tbl_deep_extend('force', DEFAULT_SEP, user_spec.sep or {})
  opts.icons = vim.tbl_deep_extend('force', icon.default, user_spec.icons or {})
  opts.enable_underline = user_spec.enable_underline
  if user_spec.enable_tabline then
    if user_spec.tabline then
      opts.tabline = vim.tbl_deep_extend('force', DEFAULT_TABLINE, user_spec.tabline or {})
      if not opts.tabline.tabs then
        opts.tabline.tabs = _set_tabline_tabs(opts.frame)
      end
      if not opts.tabline.buffers then
        opts.tabline.buffers = _set_tabline_buffers(opts.frame)
      end
    else
      opts.tabline = DEFAULT_TABLINE
    end
    M.set_hl_tab = _set_hl_tab
    M.set_hl_tab(user_spec.enable_underline)
    vim.go.showtabline = 2
  end
  if user_spec.enable_statusline then
    if user_spec.statusline then
      opts.statusline = vim.tbl_deep_extend('force', DEFAULT_STATUSLINE, user_spec.statusline or {})
    else
      opts.statusline = DEFAULT_STATUSLINE
    end
    M.set_hl_status = _set_hl_status
    M.set_hl_status(user_spec.enable_underline)
  end
  if user_spec.enable_statuscolumn then
    opts.statuscolumn = user_spec.statuscolumn or DEFAULT_STATUSCOLUMN
  end
  if user_spec.enable_fade then
    opts.enable_fade = user_spec.enable_fade
    M.set_hl_fade = _set_hl_fade
    M.set_hl_fade()
    vim.opt_local.winhighlight:append('NormalNC:StabaNC,StatuslineNC:StabaStatusNC')
  end
  if user_spec.mode_line then
    M.set_hl_mode = _set_hl_mode
    M.set_hl_mode(user_spec.mode_line)
  end

  return opts
end

return M
