local utils = require("monorepo.utils")
local messages = require("monorepo.messages")

local M = {}

M.monorepoVars = {}
M.currentMonorepo = vim.fn.getcwd()

-- Config could include:
-- Data path?
-- Silent?
-- Disable autochdir false
-- Autoload
M.setup = function(config)
  local config = config or {}
  M.currentMonorepo = vim.fn.getcwd()
  vim.opt.autochdir = false

  utils.load(M)

  -- idk if this is bad practice but I had weird issues where
  -- sometimes telescope would load before my setup function
  -- and cause the picker to bug out
  local has_telescope, telescope = pcall(require, "telescope")
  if has_telescope then
    telescope.load_extension("monorepo")
  end
end

---@param dir string|nil
M.add_current_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    vim.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  local projects = M.monorepoVars[M.currentMonorepo]
  if not dir or dir == "" then
    vim.notify(messages.NOT_IN_SUBPROJECT)
    return
  end
  if vim.tbl_contains(projects, dir) then
    vim.notify(messages.DUPLICATE_PROJECT)
    return
  end
  projects = table.insert(projects or {}, dir)
  vim.notify(messages.ADDED_PROJECT .. ": " .. dir)
  utils.save()
end

---@param dir string|nil
M.remove_current_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    vim.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  local projects = M.monorepoVars[M.currentMonorepo]
  if not dir or dir == "" then
    vim.notify(messages.NOT_IN_SUBPROJECT)
    return
  end
  if not vim.tbl_contains(projects, dir) then
    vim.notify(messages.CANT_REMOVE_PROJECT)
    return
  end
  projects = table.remove(projects, vim.tbl_get(projects, dir))
  vim.notify(messages.REMOVED_PROJECT .. ": " .. dir)
  utils.save()
end

---@param dir string|nil
M.toggle_current_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    vim.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  -- if starts with /
  local projects = M.monorepoVars[M.currentMonorepo]

  if not dir or dir == "" then
    vim.notify(messages.NOT_IN_SUBPROJECT)
    return
  end

  if vim.tbl_contains(projects, dir) then
    projects = table.remove(projects, vim.tbl_get(projects, dir))
    vim.notify(messages.REMOVED_PROJECT .. ": " .. dir)
    utils.save()
    return
  else
    projects = table.insert(projects or {}, dir)
    vim.notify(messages.ADDED_PROJECT .. ": " .. dir)
    utils.save()
    return
  end
end

return M
