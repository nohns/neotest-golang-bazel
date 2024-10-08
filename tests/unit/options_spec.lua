local options = require("neotest-golang-bazel.options")

describe("Options are set up", function()
    it("With defaults", function()
        local expected_options = {
            dap_go_enabled = false,
            dap_go_opts = {},
            runner = "go",
            go_test_args = {
                "-v",
                "-race",
                "-count=1",
            },
            gotestsum_args = { "--format=standard-verbose" },
            warn_test_name_dupes = true,
            warn_test_not_executed = true,
            dev_notifications = false,
        }
        options.setup()
        assert.are_same(expected_options, options.get())
    end)

    it("With non-defaults", function()
        local expected_options = {
            dap_go_enabled = false,
            dap_go_opts = {},
            runner = "go",
            go_test_args = {
                "-v",
                "-race",
                "-count=1",
                "-parallel=1", -- non-default
            },
            gotestsum_args = { "--format=standard-verbose" },
            warn_test_name_dupes = true,
            warn_test_not_executed = true,
            dev_notifications = false,
        }
        options.setup(expected_options)
        assert.are_same(expected_options, options.get())
    end)
end)
