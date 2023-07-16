local Path = require("plenary.path")

local M = {}

-- Get the relative directory of path param,
---@param file string
---@param netrw boolean
---@return string|nil
M.get_project_directory = function(file, netrw)
  local currentMonorepo = require("monorepo").currentMonorepo
  local idx = string.find(file, currentMonorepo, 1, true)
  if idx then
    local relative_path = string.sub(file, idx + #currentMonorepo + 0)
    -- If netrw then string is already a diretory
    if netrw then
      return relative_path
    end
    -- If not netrw then remove filename from string
    local project_directory = string.match(relative_path, "(.-)[^/]+$") -- remove filename
    project_directory = project_directory:sub(1, -2) -- remove trailing slash
    return project_directory
  else
    return nil
  end
end

-- Save monorepoVars to data_path/monorepo.json
M.save = function()
  local monorepoVars = require("monorepo").monorepoVars
  local data_path = require("monorepo").config.data_path
  local persistent_json = data_path .. "/monorepo.json"
  Path:new(persistent_json):write(vim.fn.json_encode(monorepoVars), "w")
end

-- Load json file from data_path/monorepo.json into init module.
---@return boolean, table|nil
M.load = function()
  local module = require("monorepo")
  local data_path = module.config.data_path
  local persistent_json = data_path .. "/monorepo.json"
  local status, load = pcall(function()
    return vim.json.decode(Path:new(persistent_json):read())
  end, persistent_json)

  if status and load then
    module.monorepoVars = load
    if not module.monorepoVars[module.currentMonorepo] then
      module.monorepoVars[module.currentMonorepo] = { "/" }
    end
  else
    module.monorepoVars = {}
    module.monorepoVars[module.currentMonorepo] = { "/" }
  end

  module.currentProjects = module.monorepoVars[module.currentMonorepo]
end

-- Extend vim.notify to include silent option
M.notify = function(message)
  if require("monorepo").config.silent then
    return
  end
  vim.notify(message)
end

M.index_of = function(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

M.format_path = function(path)
  -- Remove leading ./ and add leading /
  if path:sub(1, 2) == "./" then
    path = path:sub(2)
  end
  -- Add leading /
  if path:sub(1, 1) ~= "/" then
    path = "/" .. path
  end
  return path
end

return M
