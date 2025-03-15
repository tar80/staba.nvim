local M = {}
local symbol = require('staba.icon.symbol')
local ui = require('staba.icon.ui')

STABA_LOGO = ''

M.default = {
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
    Error = { symbol.severity.Error, 'DiagnosticSignError' },
    Warn = { symbol.severity.Warn, 'DiagnosticSignWarn' },
    Hint = { symbol.severity.Hint, 'DiagnosticSignHint' },
    Info = { symbol.severity.Info, 'DiagnosticSignInfo' },
  },
  status = {
    lock = { symbol.status.lock, 'StabaReadonly' },
    unlock = symbol.status.unlock,
    modify = { symbol.status.modify, 'StabaModified' },
    nomodify = symbol.status.nomodify,
    unopen = { symbol.status.unopen, 'StabaSpecial' },
    open = symbol.status.open,
    rec =  symbol.status.rec2,
  },
}

return M
