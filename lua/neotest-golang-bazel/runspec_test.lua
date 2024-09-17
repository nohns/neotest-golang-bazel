--- Helpers to build the command and context around running a single test.

local convert = require("neotest-golang-bazel.convert")
local options = require("neotest-golang-bazel.options")
local cmd = require("neotest-golang-bazel.cmd")
local dap = require("neotest-golang-bazel.dap")

local M = {}

--- Build runspec for a single test
--- @param pos neotest.Position
--- @param strategy string
--- @return neotest.RunSpec | neotest.RunSpec[] | nil
function M.build(pos, strategy)
    --- @type string
    local test_folder_absolute_path = string.match(pos.path, "(.+)/")
    local golist_data = cmd.golist_data(test_folder_absolute_path)
    local go_root = golist_data[1].Module.Dir

    --- @type string
    local test_name = convert.to_gotest_test_name(pos.id)
    test_name = convert.to_gotest_regex_pattern(test_name)

    local test_cmd, json_filepath = cmd.test_command_in_package_with_regexp(
        go_root,
        test_folder_absolute_path,
        test_name
    )

    local runspec_strategy = nil
    if strategy == "dap" then
        if options.get().dap_go_enabled then
            runspec_strategy = dap.get_dap_config(test_name)
            dap.setup_debugging(test_folder_absolute_path)
        end
    end

    --- @type RunspecContext
    local context = {
        pos_id = pos.id,
        pos_type = "test",
        golist_data = golist_data,
        parse_test_results = true,
        test_output_json_filepath = json_filepath,
    }

    local cwd = test_folder_absolute_path
    if options.get().runner == "bazel" then
        cwd = go_root
    end

    --- @type neotest.RunSpec
    local run_spec = {
        command = test_cmd,
        cwd = cwd,
        context = context,
    }

    if runspec_strategy ~= nil then
        run_spec.strategy = runspec_strategy
        run_spec.context.parse_test_results = false
    end

    return run_spec
end

return M
