local finders = require("telescope.finders")
local conf = require("telescope.config").values
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local data_path = vim.fn.stdpath("data")
local persistent_json = string.format("%s/monorepo.json", data_path)

MonorepoVars = {
	projects = {},
}

-- Something like this structure?:
-- Vars = {
--   monorepos = {
--     name = "project name",
--     projects = {},
--   }
-- }

Messages = {
	NOT_IN_SUBPROJECT = "Not in a project",
	DUPLICATE_PROJECT = "Project already added",
	ADDED_PROJECT = "Added project",
	NO_PROJECTS = "No projects added",
	SWITCHED_PROJECT = "Switched to project",
}

M.setup = function(config)
	-- Load in config
	local config = config or {}
	M.get_monorepo()
end

M.get_monorepo = function()
	MonorepoVars.monorepo = vim.fn.getcwd()
	table.insert(MonorepoVars.projects, "/")
end

M.get_project_directory = function(file, netrw)
	local idx = string.find(file, MonorepoVars.monorepo, 1, true)
	if idx then
		local relative_path = string.sub(file, idx + #MonorepoVars.monorepo + 0)
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
	if not dir or dir == "" then
		vim.notify(Messages.NOT_IN_SUBPROJECT)
		return
	end
	if vim.tbl_contains(MonorepoVars.projects, dir) then
		vim.notify(Messages.DUPLICATE_PROJECT)
		return
	end
	table.insert(MonorepoVars.projects, dir)
	vim.notify(Messages.ADDED_PROJECT .. ": " .. dir)
end

M.find_projects = function()
	local projects = MonorepoVars.projects
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
	vim.cmd("cd " .. MonorepoVars.monorepo .. "/" .. selection.value)
	vim.notify(Messages.SWITCHED_PROJECT .. ": " .. selection.value)
end

M.log = function()
	local projects = MonorepoVars.projects
	vim.notify(MonorepoVars.monorepo)
	for _, project in ipairs(projects) do
		vim.notify(project)
	end
end

return M
