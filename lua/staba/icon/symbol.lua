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
}
M.logo = {
  nvim = '',
  vim = '',
  lua = '',
}
M.mark = {
  circle = '',
  circle2 = '',
  square = '■',
  square2 = '',
  square3 = '󰄮',
  square4 = '󱓻',
  star = '󰙴',
}
M.state = {
  success = '',
  failure = '',
  pending = '',
}
M.os = {
  dos = '',
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
