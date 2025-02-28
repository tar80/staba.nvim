local M = {}

M.bufinfo = {
  alphabet = { tab = 'ᵀ', buffer = 'ᴮ', modified = 'ᴹ', unopened = 'ᵁ' },
  symbol = { tab = '^', buffer = '*', modified = '+', unopened = '~' },
}

M.fold = {
  filled = { open = '󰍝', close = '󰍟', blank = ' ' },
  filled_double = { open = ' ', close = ' ', blank = '  ' },
  outlined = { open = '󰅀', close = '󰅂', blank = ' ' },
  outlined_double = { open = ' ', close = ' ', blank = '  ' },
}

M.frame = {
  arrow = { left = '', right = '' },
  bubble = { left = '', right = '' },
  slant_u = { left = '', right = '' },
  slant_d = { left = '', right = '' },
  slant_t = { left = '', right = '' },
  bar = { left = '▐', right = '▍' },
}

M.sep = {
  arrow = { left = '', right = '' },
  bubble = { left = '', right = '' },
  slant = { left = '', right = '' },
}

M.bar = {
  thin = '│',
  midium = '┃',
  thick = '▋',
}

return M
