local Path = require("plenary.path")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local data_path = vim.fn.stdpath("data")
local persistent_json = string.format("%s/monorepo.json", data_path)

-- Something like this structure?:
-- MonorepoVars = {
--   [proj] = {},
-- }
MonorepoVars = MonorepoVars or {}
CurrentMonorepo = ""

Messages = {
	NOT_IN_SUBPROJECT = "Not in a project",
	DUPLICATE_PROJECT = "Project already added",
	CANT_REMOVE_PROJECT = "Project not in monorepo",
	REMOVED_PROJECT = "Removed project",
	ADDED_PROJECT = "Added project",
	NO_PROJECTS = "No projects added",
	SWITCHED_PROJECT = "Switched to project",
	SAVED = "Saved",
}

M.setup = function(config)
	-- Load in config
	local config = config or {}
	CurrentMonorepo = vim.fn.getcwd()

	local status, load = pcall(M.load_data, persistent_json)

	if status then
		MonorepoVars = load
		if not MonorepoVars[CurrentMonorepo] then
			MonorepoVars[CurrentMonorepo] = { "/" }
		end
	else
		MonorepoVars = {}
		MonorepoVars[CurrentMonorepo] = { "/" }
	end
end

M.load_data = function(path)
	return vim.json.decode(Path:new(path):read())
end

M.get_project_directory = function(file, netrw)
	local idx = string.find(file, CurrentMonorepo, 1, true)
	if idx then
		local relative_path = string.sub(file, idx + #CurrentMonorepo + 0)
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

M.add_current_project = function()
	local dir = M.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
	local projects = MonorepoVars[CurrentMonorepo]
	if not dir or dir == "" then
		vim.notify(Messages.NOT_IN_SUBPROJECT)
		return
	end
	if vim.tbl_contains(projects, dir) then
		vim.notify(Messages.DUPLICATE_PROJECT)
		return
	end
	projects = table.insert(projects or {}, dir)
	vim.notify(Messages.ADDED_PROJECT .. ": " .. dir)
	M.save()
end

M.remove_current_project = function()
	local dir = M.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
	local projects = MonorepoVars[CurrentMonorepo]
	if not dir or dir == "" then
		vim.notify(Messages.NOT_IN_SUBPROJECT)
		return
	end
	if not vim.tbl_contains(projects, dir) then
		vim.notify(Messages.CANT_REMOVE_PROJECT)
		return
	end
	projects = table.remove(projects, vim.tbl_get(projects, dir))
	vim.notify(Messages.REMOVED_PROJECT .. ": " .. dir)
	M.save()
end

M.toggle_current_project = function()
	local dir = M.get_project_directory(vim.api.nvim_buf_get_name(0), vim.bo.filetype == "netrw")
	local projects = MonorepoVars[CurrentMonorepo]

	if not dir or dir == "" then
		vim.notify(Messages.NOT_IN_SUBPROJECT)
		return
	end

	if vim.tbl_contains(projects, dir) then
		projects = table.remove(projects, vim.tbl_get(projects, dir))
		vim.notify(Messages.REMOVED_PROJECT .. ": " .. dir)
		M.save()
		return
	else
		projects = table.insert(projects or {}, dir)
		vim.notify(Messages.ADDED_PROJECT .. ": " .. dir)
		M.save()
		return
	end
end

M.find_projects = function()
	local projects = MonorepoVars[CurrentMonorepo]
	local opts = {}
	if #projects == 0 then
		vim.notify(Messages.NO_PROJECTS)
		return
	end
	pickers
		.new(opts, {
			prompt_title = "Monorepo Projects",
			finder = finders.new_table({
				results = projects,
			}),
			sorter = conf.file_sorter(opts),
			attach_mappings = function()
				actions.select_default:replace(M.select_project)
				return true
			end,
		})
		:find()
end

M.select_project = function(prompt_bufnr)
	actions.close(prompt_bufnr)
	local selection = action_state.get_selected_entry()
	vim.cmd("cd " .. CurrentMonorepo .. "/" .. selection.value)
	vim.notify(Messages.SWITCHED_PROJECT .. ": " .. selection.value)
end

M.save = function()
	Path:new(persistent_json):write(vim.fn.json_encode(MonorepoVars), "w")
end

return M
