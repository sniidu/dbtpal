local log = require "dbtpal.log"
local projects = require "dbtpal.projects"

local M = {}

local manifest_path = projects._find_project_dir() .. "/target/manifest.json"

-- Works only when dbt_project.yml in its default position
local get_manifest = function()
    local project = projects._find_project_dir()
    local content
    if project then
        local file = assert(io.open(project .. "/target/manifest.json", "r"))
        io.flush()
        content = vim.json.decode(file:read "*a")
    else
        log.debug "no project found - no manifest"
    end
    return content or {}
end

-- Refresh manifest when needed
local refresh_manifest = function() M.manifest = get_manifest() end

-- Initially populate manifest
refresh_manifest()
M.current_project = M.manifest["metadata"]["project_name"]

M.current_object = function()
    local current_path = vim.fn.expand "%:p:h"
    local current_filename = vim.fn.expand "%:t:r"

    -- Resolve object type
    -- TODO: find better way to achieve this, and if not, use paths from project.yml
    local object_type = nil
    if current_path:find "dbt/models" then
        object_type = "model"
    elseif current_path:find "dbt/snapshots" then
        object_type = "snapshot"
    elseif current_path:find "dbt/tests" then
        object_type = "test"
    else
        log.warn "dbt-object unidentifiable"
    end

    if object_type == nil then return {} end

    return object_type .. "." .. M.current_project .. "." .. current_filename
end

M.object_details = function(object) return M.manifest["nodes"][object] or {} end

M.child_map = function(object) return M.manifest["child_map"][object] end
M.parent_map = function(object) return M.manifest["parent_map"][object] end
M.current = function() return M.object_details(M.current_object()) end

M._parse_current = function()
    local tbl = {}

    -- return empty table in case not found from manifest
    if next(M.current()) == nil then return tbl end

    table.insert(tbl, "name: " .. M.current()["name"])
    table.insert(tbl, "database: " .. M.current()["config"]["database"])
    table.insert(tbl, "schema: " .. M.current()["config"]["schema"])
    table.insert(tbl, "materialized: " .. M.current()["config"]["materialized"])
    table.insert(tbl, "tags: " .. vim.inspect(M.current()["config"]["tags"]))
    table.insert(tbl, "enabled: " .. tostring(M.current()["config"]["enabled"]))
    table.insert(tbl, "")
    table.insert(
        tbl,
        M.current()["config"]["database"] .. "." .. M.current()["config"]["schema"] .. "." .. M.current()["name"]
    )
    return tbl
end

-- Logic for monitoring manifest changes
local uv = vim.uv
local last_modified_time = nil

local function get_file_modification_time(filepath)
    local stat = uv.fs_stat(filepath)
    return stat and stat.mtime.sec or last_modified_time
end

local function start_manifest_monitoring(filepath, interval)
    last_modified_time = get_file_modification_time(filepath)

    uv.new_timer():start(0, interval, function()
        local current_mod_time = get_file_modification_time(filepath)
        if current_mod_time and current_mod_time ~= last_modified_time then
            last_modified_time = current_mod_time
            vim.schedule(function() refresh_manifest() end)
        end
    end)
end

-- query for manifest changes every 10 secs
start_manifest_monitoring(manifest_path, 10000)

return M
