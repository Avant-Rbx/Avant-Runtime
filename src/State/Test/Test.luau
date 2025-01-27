--State for a test, including sub-tests.
--!strict

local Test = {}
Test.__index = Test

export type TestState = "NOTRUN" | "INPROGRESS" | "PASSED" | "FAILED" | "SKIPPED"
export type TestContentsState = "NORMAL" | "UPDATED" | "MISSING"
export type OutputEntry = {
    Time: number,
    MessageType: Enum.MessageType,
    Contents: {any},
}
export type Test = {
    Name: string,
    SortIndex: number,
    State: TestState,
    ContentsState: TestContentsState,
    ModuleScript: ModuleScript?,
    Output: {OutputEntry},
    ChildTests: {Test},
} & typeof(setmetatable({}, Test))



--[[
Creates a test.
--]]
function Test.new(): Test
    return setmetatable({
        Name = "Unnamed",
        SortIndex = 1,
        State = "NOTRUN" :: TestState,
        ContentsState = "NORMAL" :: TestContentsState,
        Output = {},
        ChildTests = {},
    }, Test) :: Test
end

--[[
Creates an uninitialized child test.
--]]
function Test.CreateChildTest(self: Test): Test
    local NewTest = Test.new()
    table.insert(self.ChildTests, NewTest)
    return NewTest
end

--[[
Adds an output to the test.
--]]
function Test.AddOutput(self: Test, MessageType: Enum.MessageType, ...: any): ()
    table.insert(self.Output, {
        Time = tick(),
        MessageType = MessageType,
        Contents = table.pack(...), 
    } :: OutputEntry)
end

--[[
Adds an output to the test.
If a different test is found to be correct for adding the output, it will be used instead.
--]]
function Test.AddOutputForCall(self: Test, MessageType: Enum.MessageType, ...: any): ()
    --Attempt to find a call to add output.
    local CurrentIndex = 0
    while true do
        --Get the function and return if it doesn't exist (end of stack).
        CurrentIndex = CurrentIndex + 1
        local Function = debug.info(coroutine.running(), CurrentIndex, "f")
        if Function == nil then break end

        --Get the AddTestOutput function and the function it is fore.
        --RunTestFunctionHash is checked to ensure the function is a test function (not created under one and inheriting that environment).
        --A string version of the function is used to mitigate a potential memory leak.
        local FunctionEnvironment = getfenv(Function)
        local AddTestOutput = FunctionEnvironment.AddTestOutput :: (Enum.MessageType, ...any) -> ()
        local RunTestFunctionHash = FunctionEnvironment.RunTestFunctionHash
        if not AddTestOutput or tostring(Function) ~= RunTestFunctionHash then continue end

        --Call AddTestOutput if it is valid and return.
        AddTestOutput(MessageType, ...)
        return
    end

    --Add the output to the current test.
    self:AddOutput(MessageType, ...)
end

--[[
Clears the output.
--]]
function Test.ClearOutput(self: Test): ()
    self.Output = {}
end

--[[
Removes a child test.
--]]
function Test.RemoveChildTest(self: Test, ChildTest: Test): ()
    local Index = table.find(self.ChildTests, ChildTest)
    if not Index then return end
    table.remove(self.ChildTests, Index)
end



return Test