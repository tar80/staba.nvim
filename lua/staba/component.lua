local M = {}
local util = require('staba.util')
local icons = require('staba.cache'):get('icons')
local bufs = require('staba.cache'):get('bufs')

---@param buf_status BufferStatus
---@return string
local function join_path(buf_status)
  local bufname = buf_status.no_name
  local alternate = buf_status.alternate and '# ' or ''
  if buf_status.name ~= '' then
    if buf_status.buftype ~= '' then
      bufname = util.extract_filename(buf_status.name)
    else
      local filename = util.extract_filename(buf_status.name)
      if buf_status.parent ~= '' then
        local parent = util.extract_filename(vim.fs.dirname(buf_status.name))
        local sep = buf_status.shellslash
        filename = parent .. sep .. filename
      end
      bufname = filename
    end
  end
  return alternate .. bufname
end

M.staba_logo = function()
  return icons.logo .. '%*'
end

M.icon_adjuster = function()
  return icons.adjuster
end

M.shellslash = function(buf_info)
  return buf_info.shellslash
end

---@param buf_info BufInfo
---@return string
M.bufinfo = function(buf_info)
  local label = icons.bufinfo
  local exp = ''
  vim.iter(buf_info.format):each(function(element)
    ---@type string|integer
    local value
    if element == 'tab' then
      value = label.tab .. buf_info.tab
    elseif element == 'buffer' then
      value = label.buffer .. buf_info.buffer
    elseif element == 'modified' then
      value = label.modified .. buf_info.modified
    elseif element == 'unopened' then
      value = label.unopened .. buf_info.unopened
    else
      value = tostring(element)
    end
    exp = exp .. value
  end)
  return exp
end

M.devicon = function(buf_status, is_active)
  local buf = bufs[buf_status.bufnr]
  local ret = ''
  if buf and buf.devicon.chr ~= '' then
    local icon = buf.devicon.chr .. icons.adjuster
    ret = is_active and ('%#' .. buf.devicon.hlgroup .. '#' .. icon) or icon
  end
  return ret
end

M.nav_key = function(buf_status, _)
  return buf_status.nav_key
end
M.parent = function(buf_info)
  return ('%s '):format(util.extract_filename(buf_info.cwd))
end
M.modified = function(buf_status, _)
  return buf_status.modified and icons.status.modify or icons.status.nomodify
end
M.readonly = function(buf_status, _)
  return buf_status.readonly and icons.status.lock or icons.status.unlock
end
M.unopened = function(buf_status, _)
  return buf_status.unopened and icons.status.unopen or icons.status.open
end
M.filename = function(buf_status, _)
  return join_path(buf_status)
end
M.namestate = function(buf_status, is_active)
  local ret = join_path(buf_status)
  if buf_status.modified then
    ret = '%#StabaModified#' .. ret
  elseif buf_status.unopened then
    ret = '%#StabaSpecial#' .. ret
  elseif not is_active or buf_status.readonly then
    ret = '%#StabaReadonly#' .. ret
  else
    ret = '%*' .. ret
  end
  return ret
end

---@return string fileencoding Colored current fileencoding and a symbol
M.encoding = function()
  local fenc = vim.api.nvim_get_option_value('fileencoding', {})
  local ff = vim.api.nvim_get_option_value('fileformat', {})
  return fenc ~= '' and ('%s %%*%s '):format(icons.fileformat[ff], fenc) or ''
end

---@return string filetype Colored current filetype and a symbol
M.filetype = function(buf_status)
  local buf = bufs[buf_status.bufnr]
  local ret = buf_status.filetype
  if buf and buf.devicon.chr ~= '' then
    ret = ('%%#%s#%s %%*%s '):format(buf.devicon.hlgroup, buf.devicon.chr, ret)
  end
  return ret
end

---@return string cursor_position
M.position = function()
  local hl = '%#StabaReadonly#'
  local ln = 'Ln '
  local cn = 'Cn '
  local l = '%3l/%L'
  local c = '%3.c'
  return ('%s%s%%*%s %s%s%%*%s'):format(hl, ln, l, hl, cn, c)
end

---@return string search-count
M.search_count = function()
  if vim.v.hlsearch ~= 0 then
    local count = vim.fn.searchcount({ maxcount = 999, timeout = 250 })
    if count.incomplete ~= 1 and next(count) then
      return ('%%#Search#%d/%d%%*'):format(count.current, math.min(count.total, count.maxcount))
    end
  end

  return ''
end

M.reg_recording = function()
  local register = vim.fn.reg_recording()
  return register ~= '' and ('recording %s%s@%s'):format(icons.status.rec, icons.adjuster, register) or ''
end

---@param buf_status BufferStatus
---@return string Lsp_diagnostics
M.diagnostics = function(buf_status)
  local details = ''
  local mode = buf_status.mode

  if not (mode == 'i' or mode == 'r') then
    vim.iter({ 'Error', 'Warn', 'Info', 'Hint' }):each(function(v)
      local count = #vim.diagnostic.get(0, { severity = v })
      local detail = count > 0 and ('%s%s%s%%* '):format(icons.severity[v], icons.adjuster, count) or ''
      details = details .. detail
    end)
  end

  return details == '' and '' or ' ' .. details
end

local noice

local function load_noice()
  if not noice then
    noice = package.loaded['noice']
  end
end

M.noice_message = function(_)
  load_noice()
  if noice and noice.api.status.message.has() then
    return noice.api.status.message.get()
  end
  return ''
end

M.noice_command = function(_)
  load_noice()
  if noice then
    if noice.api.status.command.has() then
      return noice.api.status.command.get()
    end
  end
  return ''
end

M.noice_mode = function(_)
  load_noice()
  if noice then
    if noice.api.status.mode.has() then
      return noice.api.status.mode.get()
    end
  end
  return ''
end

M.noice_search = function(_)
  if not noice then
    noice = package.loaded['noice']
  end
  if noice then
    if noice.api.status.search.has() then
      return noice.api.status.search.get()
    end
  end
  return ''
end

M.snacks_profiler = function(_)
  if Snacks and Snacks.profiler.running() then
    local status = Snacks.profiler.status()
    if status.cond() then
      return ('%%#%s#%s'):format(status.color, status[1]())
    end
  end
  return ''
end

return M
