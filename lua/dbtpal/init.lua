--[[ this module exposes the interface of lua functions:
define here the lua functions that activate the plugin ]]

local main = require "dbtpal.main"
local config = require "dbtpal.config"

local M = {}

M.config = config
M.setup = config.setup

M.run = main.run
M.run_all = main.run_all
M.run_model = main.run_model
M.run_children = main.run_children
M.run_parents = main.run_parents
M.run_family = main.run_family

M.test = main.test
M.test_all = main.test_all
M.test_model = main.test_model

M.compile = main.compile
M.build = main.build

M.run_command = main.run_command

-- Show information regarding current model
M.show_info = main.show_info
M.show_compiled = main.show_compiled
M.show_run = main.show_run

-- Commands
vim.api.nvim_create_user_command("DbtRun", function() main.run() end, { nargs = 0 })

vim.api.nvim_create_user_command("DbtRunAll", function(cmd) main.run_all(cmd.args) end, { nargs = "?" })

vim.api.nvim_create_user_command("DbtRunModel", function(cmd) main.run_model(cmd.args) end, { nargs = 1 })

vim.api.nvim_create_user_command("DbtTest", function() main.test() end, { nargs = 0 })

vim.api.nvim_create_user_command("DbtTestAll", function(cmd) main.test_all(cmd.args) end, { nargs = "?" })

vim.api.nvim_create_user_command("DbtTestModel", function(cmd) main.test_model(cmd.args) end, { nargs = 1 })

vim.api.nvim_create_user_command("DbtCompile", function() main.compile() end, { nargs = 0 })

vim.api.nvim_create_user_command("DbtBuild", function() main.build() end, { nargs = 0 })

-- Debug keybindings to run dbt
-- vim.api.nvim_set_keymap("n", "<leader>dr", ":lua require('dbtpal').run()<CR>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("n", "<leader>dt", ":lua require('dbtpal').test()<CR>", { noremap = true, silent = true })

local ok, _ = pcall(require, "telescope")
if ok then
    local telescope = require "dbtpal.telescope"

    M.find_child = function() telescope.dbt_picker_child() end
    M.find_parent = function() telescope.dbt_picker_parent() end
    M.find_all = function() telescope.dbt_picker_all() end
end
return M
