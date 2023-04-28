local Path = require("plenary.path")

local data_path = vim.fn.stdpath("data")
local persistent_json = data_path .. "/monorepo.json"

local M = {}

M.get_project_directory = function(file, netrw)
  local currentMonorepo = require("monorepo").currentMonorepo
  local idx = string.find(file, currentMonorepo, 1, true)
  if idx then
    local relative_path = string.sub(file, idx + #currentMonorepo + 0)
    if netrw then
      return relative_path
    end
    local project_directory = string.match(relative_path, "(.-)[^/]+$") -- remove filename
    project_directory = project_directory:sub(1, -2) -- remove trailing slash
    return project_directory
  else
    return nil
  end
end

M.save = function()
  local monorepoVars = require("monorepo").monorepoVars
  Path:new(persistent_json):write(vim.fn.json_encode(monorepoVars), "w")
end

-- Load json file from data_path/monorepo.json into init module.
--
-- Passing module here to avoid having to use global vars.
-- I'm tired tho so this could be stupid...
---@param module table
---@return boolean, table|nil
M.load = function(module)
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

return M
