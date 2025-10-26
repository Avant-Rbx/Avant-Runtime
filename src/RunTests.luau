--Simple test runner that runs all tests in the game.
--This most likely won't be used directly due to how simple it is, but exists for quick testing.
--!strict

local MESSAGE_TYPE_TO_NAME = {
    [Enum.MessageType.MessageOutput] = "OUTPUT",
    [Enum.MessageType.MessageWarning] = "WARNING",
    [Enum.MessageType.MessageError] = "ERROR",
    [Enum.MessageType.MessageInfo] = "INFO",
}

local RunModuleScript = require(script.Parent:WaitForChild("Runner"):WaitForChild("RunModuleScript"))
local Test = require(script.Parent:WaitForChild("State"):WaitForChild("Test"):WaitForChild("Test"))
local MdouleScriptDiscovery = require(script.Parent:WaitForChild("State"):WaitForChild("Discovery"):WaitForChild("ModuleScriptDiscovery"))
local AvantConfiguration = require(script.Parent:WaitForChild("State"):WaitForChild("AvantConfiguration"))
local FormatLines = require(script.Parent:WaitForChild("Util"):WaitForChild("FormatLines"))



--[[
Outputs the results of a test.
--]]
local function OutputTest(TestInstance: Test.Test, Prefix: string, StateSummary: {[Test.TestState]: number}): ()
    --Print the test information.
    local DurationText = nil
    if TestInstance.StartTime and TestInstance.EndTime then
        DurationText = ` ({string.format("%.3f", TestInstance.EndTime - TestInstance.StartTime)} seconds)`
    end
    local TestMessage = `{Prefix}[{TestInstance.State}] {TestInstance.Name}{DurationText}`
    if TestInstance.State == "PASSED" then
        print(TestMessage)
    else
        warn(TestMessage)
        for _, Output in TestInstance.Output do
            local Lines = FormatLines(Output.Contents, Output.ContentsSize)
            for _, Line in Lines do
                local Message = `{Prefix}    [{MESSAGE_TYPE_TO_NAME[Output.MessageType]}] {Line}`
                if Output.MessageType == Enum.MessageType.MessageOutput then
                    print(Message)
                else
                    warn(Message)
                end
            end
        end
    end

    --Add the total.
    if StateSummary[TestInstance.State] then
        StateSummary[TestInstance.State] += 1
    end

    --Print the child tests.
    for _, ChildTest in TestInstance.ChildTests do
        OutputTest(ChildTest :: Test.Test, `{Prefix}    `, StateSummary)
    end
end



return function()
    local StateSummary = {
        NOT_RUN = 0,
        PASSED = 0,
        FAILED = 0,
        SKIPPED = 0,
    }

    --Discover the ModuleScript tests.
    local Configuration = AvantConfiguration.GetInstance()
    local ModuleScriptDiscoveryInstance = MdouleScriptDiscovery.new(game)
    local ModuleScriptTests = {}
    for _, ChildTest in ModuleScriptDiscoveryInstance.RootTest.ChildTests do
        if ChildTest.ModuleScript and Configuration:IsIgnored(ChildTest.ModuleScript:GetFullName()) then continue end
        table.insert(ModuleScriptTests, ChildTest)
    end
    table.sort(ModuleScriptTests, function(a, b) return a.Name < b.Name end)
    ModuleScriptDiscoveryInstance:Destroy()

    --Run the tests.
    for _, ModuleScriptTest in ModuleScriptTests do
        print(`Running test \"{ModuleScriptTest.Name}\"...`)
        RunModuleScript(ModuleScriptTest :: Test.Test)
        OutputTest(ModuleScriptTest :: Test.Test, "", StateSummary)
    end

    --Print the summary.
    print("\nTest summary:")
    for State, Total in StateSummary do
        print(`    {State}: {Total}`)
    end

    --Return the summary.
    return StateSummary
end