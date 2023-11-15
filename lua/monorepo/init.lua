local utils = require("monorepo.utils")
local messages = require("monorepo.messages")

local M = {}

M.monorepoVars = {}
M.currentMonorepo = vim.fn.getcwd()

M.config = {
  silent = false,
  autoload_telescope = true,
  data_path = vim.fn.stdpath("data"),
}

---@class pluginConfig
---@field silent boolean
---@field autoload_telescope boolean
---@field data_path string
---@param config? pluginConfig
M.setup = function(config)
  -- Overwrite default config with user config
  if config then
    for k, v in pairs(config) do
      M.config[k] = v
    end
  end

  vim.opt.autochdir = false
  utils.load() -- Load monorepo.json

  -- I don't know if this is bad practice but I had weird issues where
  -- sometimes telescope would load before my setup function
  -- and cause the picker to bug out
  if M.config.autoload_telescope then
    local has_telescope, telescope = pcall(require, "telescope")
    if has_telescope then
      telescope.load_extension("monorepo")
    end
  end

  vim.api.nvim_create_autocmd("SessionLoadPost", {
    callback = function()
      M.change_monorepo(vim.fn.getcwd())
    end,
  })
end

-- If no dir is passed, it will use the current buffer's directory
---@param dir string|nil
M.add_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    utils.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  local projects = M.monorepoVars[M.currentMonorepo]
  if not dir or dir == "" then
    utils.notify(messages.NOT_IN_SUBPROJECT)
    return
  end
  if vim.tbl_contains(projects, dir) then
    utils.notify(messages.DUPLICATE_PROJECT)
    return
  end
  projects = table.insert(projects or {}, dir)
  utils.notify(messages.ADDED_PROJECT .. ": " .. dir)
  utils.save()
end

-- If no dir is passed, it will use the current buffer's directory
---@param dir string|nil
M.remove_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    utils.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  local projects = M.monorepoVars[M.currentMonorepo]
  if not dir or dir == "" then
    utils.notify(messages.NOT_IN_SUBPROJECT)
    return
  end
  if not vim.tbl_contains(projects, dir) then
    utils.notify(messages.CANT_REMOVE_PROJECT)
    return
  end
  projects = table.remove(projects, utils.index_of(projects, dir))
  utils.notify(messages.REMOVED_PROJECT .. ": " .. dir)
  utils.save()
end

-- If no dir is passed, it will use the current buffer's directory
---@param dir string|nil
M.toggle_project = function(dir)
  if dir and dir:sub(1, 1) ~= "/" then
    utils.notify(messages.INVALID_PATH)
    return
  end

  dir = dir or utils.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
  -- if starts with /
  local projects = M.monorepoVars[M.currentMonorepo]

  if not dir or dir == "" then
    utils.notify(messages.NOT_IN_SUBPROJECT)
    return
  end

  if vim.tbl_contains(projects, dir) then
    projects = table.remove(projects, utils.index_of(projects, dir))
    utils.notify(messages.REMOVED_PROJECT .. ": " .. dir)
    utils.save()
    return
  else
    projects = table.insert(projects or {}, dir)
    utils.notify(messages.ADDED_PROJECT .. ": " .. dir)
    utils.save()
    return
  end
end

-- Text box prompt for editing project list.
-- Defaults to add.
---@param action "add"|"remove"|"toggle"|nil
M.prompt_project = function(action)
  if not action then
    action = "add"
  end

  if action ~= "add" and action ~= "remove" and action ~= "toggle" then
    utils.notify(messages.INVALID_ACTION)
    return
  end

  if action == "add" then
    local dir = vim.fn.input(messages.ADD_PROJECT)
    dir = utils.format_path(dir)
    M.add_project(dir)
    return
  end

  if action == "remove" then
    local dir = vim.fn.input(messages.REMOVE_PROJECT)
    dir = utils.format_path(dir)
    M.remove_project(dir)
    return
  end

  if action == "toggle" then
    local dir = vim.fn.input(messages.TOGGLE_PROJECT)
    dir = utils.format_path(dir)
    M.toggle_project(dir)
    return
  end
end

M.go_to_project = function(index)
  local project = M.monorepoVars[M.currentMonorepo][index]
  if not project then
    return
  end
  vim.api.nvim_set_current_dir(M.currentMonorepo .. "/" .. project)
  utils.notify(messages.SWITCHED_PROJECT .. ": " .. project)
end

M.next_project = function()
  local projects = M.monorepoVars[M.currentMonorepo]
  local current_project = "/"
  if vim.fn.getcwd() ~= M.currentMonorepo then
    current_project = vim.fn.getcwd():sub(#M.currentMonorepo + 1)
  end

  local index = utils.index_of(projects, current_project)
  if not index then
    return
  end
  if index == #projects then
    index = 1
  else
    index = index + 1
  end
  M.go_to_project(index)
end

M.previous_project = function()
  local projects = M.monorepoVars[M.currentMonorepo]
  local current_project = "/"
  if vim.fn.getcwd() ~= M.currentMonorepo then
    current_project = vim.fn.getcwd():sub(#M.currentMonorepo + 1)
  end

  local index = utils.index_of(projects, current_project)
  if not index then
    return
  end
  if index == 1 then
    index = #projects
  else
    index = index - 1
  end
  M.go_to_project(index)
end

M.change_monorepo = function(path)
  require("monorepo").currentMonorepo = path
  utils.load()
end

return M
