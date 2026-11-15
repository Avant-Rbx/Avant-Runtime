--Simple test runner that runs all tests in the game.
--This most likely won't be used directly due to how simple it is, but exists for quick testing.
--!strict

local INDENT = "    "
local MESSAGE_TYPE_TO_NAME = {
    [Enum.MessageType.MessageOutput] = "OUTPUT",
    [Enum.MessageType.MessageWarning] = "WARNING",
    [Enum.MessageType.MessageError] = "ERROR",
    [Enum.MessageType.MessageInfo] = "INFO",
}
local NON_PASSING_TEST_SUMMARY_STATES = {
    "FAILED",
    "SKIPPED",
}

local RunModuleScript = require(script.Parent:WaitForChild("Runner"):WaitForChild("RunModuleScript"))
local Test = require(script.Parent:WaitForChild("State"):WaitForChild("Test"):WaitForChild("Test"))
local MdouleScriptDiscovery = require(script.Parent:WaitForChild("State"):WaitForChild("Discovery"):WaitForChild("ModuleScriptDiscovery"))
local AvantConfiguration = require(script.Parent:WaitForChild("State"):WaitForChild("AvantConfiguration"))
local FormatLines = require(script.Parent:WaitForChild("Util"):WaitForChild("FormatLines"))

type TestPathEntry = {
    Test: Test.Test,
    Level: number,
    Children: {TestPathEntry},
}



--[[
Formats the duration text of a test.
--]]
local function FormatDurationText(TestInstance: Test.Test): string?
    if not TestInstance.StartTime or not TestInstance.EndTime then return nil end
    return ` ({string.format("%.3f", TestInstance.EndTime - TestInstance.StartTime)} seconds)`
end

--[[
Outputs the results of a test.
--]]
local function OutputTest(TestInstance: Test.Test, Prefix: string, StateSummary: {[Test.TestState]: number}, NonPassingTests: {Test.Test}): ()
    --Print the test information.
    local TestMessage = `{Prefix}[{TestInstance.State}] {TestInstance.Name}{FormatDurationText(TestInstance)}`
    if TestInstance.State == "PASSED" then
        print(TestMessage)
    else
        warn(TestMessage)
        for _, Output in TestInstance.Output do
            local Lines = FormatLines(Output.Contents, Output.ContentsSize)
            for _, Line in Lines do
                local Message = `{Prefix}{INDENT}[{MESSAGE_TYPE_TO_NAME[Output.MessageType]}] {Line}`
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

    --Add the test if it didn't pass.
    if table.find(NON_PASSING_TEST_SUMMARY_STATES, TestInstance.State) then
        table.insert(NonPassingTests, TestInstance)
    end

    --Print the child tests.
    for _, ChildTest in TestInstance.ChildTests do
        OutputTest(ChildTest :: Test.Test, `{Prefix}{INDENT}`, StateSummary, NonPassingTests)
    end
end

--[[
Outputs the summary of non-passing tests.
--]]
local function OutputNonPassingTests(NonPassingTests: {Test.Test}): ()
    --Return if there are no non-passing tests.
    if #NonPassingTests == 0 then return end
    print("")
    print(`{INDENT}Non-passing tests:`)

    --Create the paths to print.
    local Paths: {TestPathEntry} = {}
    for _, TestInstance in NonPassingTests do
        --Create a stack of the tests.
        local Tests = {}
        local CurrentTestInstance: Test.Test? = TestInstance :: Test.Test
        while CurrentTestInstance do
            table.insert(Tests, 1, CurrentTestInstance)
            CurrentTestInstance = CurrentTestInstance.ParentTest
        end

        --Add the tests.
        local CurrentPath = Paths
        local CurrentLevel = 0
        while #Tests > 0 do
            --Determine the next node.
            local PathTestInstance = table.remove(Tests, 1)
            local NextPath = nil
            for _, Path in CurrentPath do
                if Path.Test ~= PathTestInstance then continue end
                NextPath = Path
                break
            end

            --Add the path if it doesn't exist. Otherwise use the provided path.
            if NextPath then
                CurrentPath = NextPath.Children :: {TestPathEntry}
            else
                local NewPath = {
                    Test = PathTestInstance,
                    Level = CurrentLevel,
                    Children = {},
                } :: TestPathEntry
                table.insert(CurrentPath, NewPath)
                CurrentPath = NewPath.Children
            end
            CurrentLevel += 1
        end
    end

    --Flatten the tests to print.
    local TestsToPrint = {}
    while #Paths > 0 do
        --Add the current entry.
        local PathEntry = table.remove(Paths, 1) :: TestPathEntry
        table.insert(TestsToPrint, {
            Test = PathEntry.Test,
            Indent = PathEntry.Level,
        })

        --Queue the next entries at the front.
        for i = #PathEntry.Children, 1, -1 do
            table.insert(Paths, 1, PathEntry.Children[i])
        end
    end

    --Print the tests.
    for _, PathEntry in TestsToPrint do
        local TestInstance = PathEntry.Test :: Test.Test
        print(`{string.rep(INDENT, PathEntry.Indent + 1)} [{TestInstance.State}] {TestInstance.Name}{FormatDurationText(TestInstance)}`)
    end
end



return function()
    local StateSummary = {
        NOT_RUN = 0,
        PASSED = 0,
        FAILED = 0,
        SKIPPED = 0,
    }
    local NonPassingTests = {}

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
        OutputTest(ModuleScriptTest :: Test.Test, "", StateSummary, NonPassingTests)
    end

    --Print the summary.
    print("\nTest summary:")
    for State, Total in StateSummary do
        print(`{INDENT}{State}: {Total}`)
    end
    OutputNonPassingTests(NonPassingTests)

    --Return the summary.
    return StateSummary
end