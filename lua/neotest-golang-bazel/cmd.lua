--- Helper functions building the command to execute.

local async = require("neotest.async")

local options = require("neotest-golang-bazel.options")
local json = require("neotest-golang-bazel.json")

local M = {}

function M.golist_data(cwd)
    -- call 'go list -json ./...' to get test file data
    local go_list_command = {
        "go",
        "list",
        "-json",
        "./...",
    }
    local output =
        vim.fn.system("cd " .. cwd .. " && " .. table.concat(go_list_command, " "))
    return json.process_golist_output(output)
end

function M.test_command_in_package(package_or_path)
    local go_test_required_args = { package_or_path }
    local cmd, json_filepath = M.test_command(go_test_required_args)
    return cmd, json_filepath
end

function M.test_command_in_package_with_regexp(go_root, package_or_path, regexp)
    if options.get().runner == "bazel" then
        local pkg = string.gsub(package_or_path, go_root, "")
        return M.bazel_test(pkg, regexp)
    end
    local go_test_required_args = { package_or_path, "-run", regexp }
    local cmd, json_filepath = M.test_command(go_test_required_args)
    return cmd, json_filepath
end

function M.test_command(go_test_required_args)
    --- The runner to use for running tests.
    --- @type string
    local runner = M.runner_fallback(options.get().runner)

    --- The filepath to write test output JSON to, if using `gotestsum`.
    --- @type string | nil
    local json_filepath = nil

    --- The final test command to execute.
    --- @type table<string>
    local cmd = {}

    if runner == "go" then
        cmd = M.go_test(go_test_required_args)
    elseif runner == "gotestsum" then
        json_filepath = vim.fs.normalize(async.fn.tempname())
        cmd = M.gotestsum(go_test_required_args, json_filepath)
    end

    return cmd, json_filepath
end

function M.go_test(go_test_required_args)
    local cmd = { "go", "test", "-json" }
    cmd = vim.list_extend(vim.deepcopy(cmd), options.get().go_test_args)
    cmd = vim.list_extend(vim.deepcopy(cmd), go_test_required_args)
    return cmd
end

function M.gotestsum(go_test_required_args, json_filepath)
    local cmd = { "gotestsum", "--jsonfile=" .. json_filepath }
    cmd = vim.list_extend(vim.deepcopy(cmd), options.get().gotestsum_args)
    cmd = vim.list_extend(vim.deepcopy(cmd), { "--" })
    cmd = vim.list_extend(vim.deepcopy(cmd), options.get().go_test_args)
    cmd = vim.list_extend(vim.deepcopy(cmd), go_test_required_args)
    return cmd
end

function M.bazel_test(test_path, regexp)
    --local json_filepath = vim.fs.normalize(async.fn.tempname())
    local json_filepath = '~/bla.json'
    local cmd = {
        'bazel',
        'test',
        '--build_tests_only',
        '--test_env=GO_TEST_WRAP_TESTV=1',
        '--build_event_json_file=' .. json_filepath,
        '--build_event_json_file_path_conversion=no',
        '--test_filter=\'' .. regexp .. '\'',
        test_path .. ':all'
    }
    return cmd, json_filepath
end

function M.runner_fallback(executable)
    if M.system_has(executable) == false then
        options.set({ runner = "go" })
        return options.get().runner
    end
    return options.get().runner
end

function M.system_has(executable)
    if vim.fn.executable(executable) == 0 then
        vim.notify("Executable not found: " .. executable, vim.log.levels.WARN)
        return false
    end
    return true
end

return M
