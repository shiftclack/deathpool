local TestHelpers = {}

if _G.date == nil then
    _G.date = function(formatString, timestamp)
        return os.date(formatString, timestamp)
    end
end

if _G.time == nil then
    _G.time = function(dateTable)
        return os.time(dateTable)
    end
end

function TestHelpers.CreateSuite()
    local suite = {
        failures = 0,
        checks = 0,
    }

    function suite:fail(message)
        self.failures = self.failures + 1
        io.stderr:write("not ok - " .. message .. "\n")
    end

    function suite:pass(message)
        local _ = self
        io.stdout:write("ok - " .. message .. "\n")
    end

    function suite:assertEquals(actual, expected, message)
        self.checks = self.checks + 1
        if actual ~= expected then
            self:fail(string.format("%s (expected %s, got %s)", message, tostring(expected), tostring(actual)))
            return
        end

        self:pass(message)
    end

    function suite:assertTruthy(value, message)
        self.checks = self.checks + 1
        if not value then
            self:fail(message)
            return
        end

        self:pass(message)
    end

    function suite:assertContains(text, needle, message)
        self.checks = self.checks + 1
        if type(text) ~= "string" or not string.find(text, needle, 1, true) then
            self:fail(message .. string.format(" (missing %s)", tostring(needle)))
            return
        end

        self:pass(message)
    end

    function suite:assertTableLength(tbl, expected, message)
        self.checks = self.checks + 1
        if #tbl ~= expected then
            self:fail(string.format("%s (expected %s, got %s)", message, tostring(expected), tostring(#tbl)))
            return
        end

        self:pass(message)
    end

    function suite:finish()
        io.stdout:write(string.format("\n%d checks, %d failures\n", self.checks, self.failures))
        if self.failures > 0 then
            os.exit(1)
        end
    end

    return suite
end

return TestHelpers
