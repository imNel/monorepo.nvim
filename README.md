# monorepo.nvim
monorepo.nvim is a plugin to manage monorepos inside of neovim! 
Its goal is to make juggling multiple projects inside of a monorepo a little easier.

## Requirements
- You'll need [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for the project picker!

## Installing

1. Install the plugin (This example uses [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "imNel/monorepo.nvim",
    config = function()
        require("monorepo").setup({
            -- Your config here!
        })
    end,
    dependencies = { "nvim-telescope/telescope.nvim" },
    dev = true,
},
```

2. Load the telescope extension (Needs to be done at any point AFTER `require("telescope").setup()` and `require("monorepo").setup()`).
You can set this step to be done automatically by setting `{ autoload = true }` in the config.
```lua
require("telescope").load_extension("monorepo")
```

3. Set up your keybinds! 
```lua
vim.keymap.set("n", "<leader>m", function()
	require("telescope").extensions.monorepo.monorepo()
end)
vim.keymap.set("n", "<leader>n", function()
	require("monorepo").toggle_current_project()
end)
```

## Usage (These can be mapped to keybinds)

You can add the current file's directory to the project list (works in netrw and files)
```lua
:lua require("monorepo").add_current_project()
```

You can also remove it if you don't want it in the project list
```lua
:lua require("monorepo").remove_current_project()
```

You can also toggle these with a single command
```lua
:lua require("monorepo").toggle_current_project()
```

You can view the project list like this
```lua
:Telescope monorepo
```
or this
```lua
:lua require("telescope").extensions.monorepo.monorepo()
```


## Does this save? Where does this save?

## Todo

1. Implement config options
2. ci/cd
3. A text box to type in a subdir
4. Add gif to README
5. Add LICENSE

Extras features I wanna add:
- project.nvim support
- Lualine support??
- NerdTree support? what are popular trees/fs plugins?
- Give projects a "nickname"?
- Include info on projects?
- When opening a known subproject, it detects it
- Remove repeated code with add, remove and toggle
- Other ways to add projects
