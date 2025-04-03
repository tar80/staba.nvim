local M = {}

M.cmdline = {
  input = '',
  search_down = '',
  search_up = '',
}
M.status = {
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
  round_square_s =  '',
  round_square_l = '󱓻',
  square_s = '■',
  square_l = '󰄮',
  star = '󰙴',
}
M.state = {
  success = '',
  failure = '',
  pending = '',
}
M.os = {
  dos = '',
  unix = '',
  mac = '',
}
M.severity = {
  Error = '',
  Warn = '',
  Hint = '',
  Info = '',
  Trace = '󱨈',
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

return M
