local M = {}
local symbol = require('staba.icon.symbol')
local ui = require('staba.icon.ui')

local STABA_LOGO = ''

M.default = {
  adjuster = '',
  logo = { STABA_LOGO, 'WarningMsg' },
  bar = ui.bar.thin,
  bufinfo = ui.bufinfo.alphabet,
  fold = ui.fold.filled,
  fileformat = {
    dos = { symbol.os.dos, 'Changed' },
    mac = { symbol.os.mac, 'Removed' },
    unix = { symbol.os.unix, 'Added' },
  },
  severity = {
    Error = { symbol.diagnostics.Error, 'DiagnosticSignError' },
    Warn = { symbol.diagnostics.Warn, 'DiagnosticSignWarn' },
    Hint = { symbol.diagnostics.Hint, 'DiagnosticSignHint' },
    Info = { symbol.diagnostics.Info, 'DiagnosticSignInfo' },
  },
  status = {
    lock = { symbol.editor.lock, 'StabaReadonly' },
    unlock = symbol.editor.unlock,
    modify = { symbol.editor.modify, 'StabaModified' },
    nomodify = symbol.editor.nomodify,
    unopen = { symbol.editor.unopen, 'StabaSpecial' },
    open = symbol.editor.open,
    rec =  symbol.editor.rec2,
    copilot = { symbol.copilot.enable, 'StabaCopilot' },
    uncopilot = { symbol.copilot.disable, 'Comment' },
  },
}

return M
