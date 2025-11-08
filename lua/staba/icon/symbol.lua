local M = {}

M.cmdline = {
  input = '',
  search_down = '',
  search_up = '',
}
M.editor = {
  edit = '󰤌',
  lock = '󰍁',
  unlock = '  ',
  modify = '󰐖',
  nomodify = '  ',
  unopen = '󰌖',
  open = '  ',
  rec1 = '󰻿',
  rec2 = '󰕧',
}
M.logo = {
  nvim = '',
  vim = '',
  lua = '',
}
M.mark = {
  circle_s = '',
  circle_sl = '',
  circle_sr = '',
  round_square_s = '',
  round_square_l = '󱓻',
  square_s = '■',
  square_l = '󰄮',
  star = '󰙴',
}
M.access = {
  success = '',
  failure = '',
  pending = '󰌚',
}
M.os = {
  dos = '',
  unix = '',
  mac = '',
}
M.diagnostics = {
  Hint = '',
  Info = '',
  Warn = '',
  Error = '',
}
M.log_levels = {
  trace = '',
  debug = '',
  info = '',
  warn = '',
  error = '',
  off = ' ',
}
M.ime = {
  hira = '󱌴',
  kata = '󱌵',
  hankata = '󱌶',
  zenkaku = '󰚞',
  abbrev = '󱌯',
  [''] = '',
}
M.git = {
  branch = '',
  branch2 = '',
}
M.copilot = {
  enable = '',
  disable = '',
}

return M
