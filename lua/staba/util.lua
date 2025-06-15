---@class util
local M = {}

-- Returns "value" if the "bool" is true, and "nil" if it is false.
---@generic T ...
---@param bool boolean
---@param ... T
---@return T|nil
function M.value_or_nil(bool, ...)
  return vim.F.ok_or_nil(bool, ...)
  -- return bool == true and value or nil
end

-- Returns a closure for formatting a message with a given "name".
---@param name string The "name" to be used in the message formatting.
---@return function - A closure that takes a "message" string and returns the formatted message with "name".
function M.name_formatter(name)
  return function(message)
    return (message):format(name)
  end
end

---@alias valueType "number"|"string"|"boolean"|"table"|"function"|"thread"|"userdata"
-- A closure function that returns one of the two arguments based on the type of `value` determined in advance.
---@param value any The value to be evaluated.
---@param validator valueType The type to compare against.
---@return function #A closure that returns <arg1> if "value" matches the type of "validator", otherwise returns <arg2>.
function M.evaluated_condition(value, validator)
  return value == validator and function(t, _)
    return t
  end or function(_, f)
    return f
  end
end

local rgx_filename = '^.*[\\/]'

-- Extracts the filename from a given "filepath".
---@param filepath string The full path from which to extract the filename.
---@return string, number - The extracted filename, and replacement count.
function M.extract_filename(filepath)
  return filepath:gsub(rgx_filename, '', 1)
end

local rgx_fileext = '^.*%.'

-- Extracts the extension from a given "filepath".
---@param filepath string The full path from which to extract the filename.
---@return string, number - The extracted extension, and replacement count.
function M.extract_fileext(filepath)
  return filepath:gsub(rgx_fileext, '', 1)
end

return M
