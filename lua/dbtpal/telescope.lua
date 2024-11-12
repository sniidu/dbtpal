local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
-- local themes = require "telescope.themes"

local config = require "dbtpal.config"
local manifest = require "dbtpal.manifest"

local M = {}

M.dbt_models = function(tbl, opts)
    opts = opts or {}

    pickers
        .new(opts, {
            prompt_title = "dbt",
            finder = finders.new_table {

                results = tbl,
                entry_maker = function(entry)
                    return {
                        value = entry,
                        display = entry.unique_id,
                        ordinal = entry.unique_id,
                        path = config.options.path_to_dbt_project .. "/" .. entry.original_file_path,
                    }
                end,
            },

            sorter = conf.file_sorter(),
            previewer = conf.grep_previewer(opts),
        })
        :find()
end

local picker_manifest_prep = function(tbl, project_only)
    local res = {}
    for _, val in pairs(tbl) do
        if project_only and val.package_name == manifest.current_project then table.insert(res, val) end
    end
    return res
end

local map_has_value = function(map, val)
    for _, value in ipairs(map) do
        if value == val then return true end
    end
    return false
end

local filter_manifest_nodes = function(manifest_nodes, filter)
    local res = {}
    for key, val in pairs(manifest_nodes) do
        if map_has_value(filter, key) then res[key] = val end
    end
    return res
end

M.dbt_picker = function(nodes, opts)
    local res = picker_manifest_prep(nodes, true)
    M.dbt_models(res, opts)
end

M.dbt_picker_all = function() M.dbt_picker(manifest.manifest["nodes"]) end
M.dbt_picker_child = function()
    M.dbt_picker(filter_manifest_nodes(manifest.manifest["nodes"], manifest.child_map(manifest.current_object())))
end

M.dbt_picker_parent = function()
    M.dbt_picker(filter_manifest_nodes(manifest.manifest["nodes"], manifest.parent_map(manifest.current_object())))
end

return M
