--State for a test, including sub-tests.
--!strict

local UNIT_TEST_STATE_PRIORITY = {
    NOT_RUN = 1,
    PASSED = 2,
    SKIPPED = 3,
    FAILED = 4,
    IN_PROGRESS = 5,
} :: {[TestState]: number}

local NexusInstance = require(script.Parent.Parent.Parent:WaitForChild("Packages"):WaitForChild("NexusInstance"))

local Test = {}
Test.__index = Test

local NexusInstanceTest = NexusInstance.ToInstance(Test) :: NexusInstance.NexusInstanceClass<typeof(Test), () -> (Test)>

export type TestState = "NOT_RUN" | "IN_PROGRESS" | "PASSED" | "FAILED" | "SKIPPED"
export type TestContentsState = "NORMAL" | "UPDATED" | "MISSING"
export type OutputEntry = {
    Time: number,
    MessageType: Enum.MessageType,
    Contents: {any},
    ContentsSize: number,
}
export type BaseTest = {
    Name: string,
    SortIndex: number,
    Hidden: boolean,
    State: TestState,
    CombinedState: TestState,
    ContentsState: TestContentsState,
    ModuleScript: ModuleScript?,
    Output: {OutputEntry},
    StartTime: number?,
    EndTime: number?,
    ParentTest: Test?,
    ChildTests: {Test},
    TestAdded: NexusInstance.TypedEvent<Test>,
    TestRemoved: NexusInstance.TypedEvent<Test>,
    OutputAdded: NexusInstance.TypedEvent<OutputEntry>,
    OutputCleared: NexusInstance.TypedEvent<>,
} & typeof(setmetatable({}, Test))
export type Test = NexusInstance.NexusInstance<BaseTest>



--[[
Creates a test.
--]]
function Test.__new(self: Test): ()
    self.Name = "Unnamed"
    self.SortIndex = 1
    self.Hidden = false
    self.State = "NOT_RUN" :: TestState
    self.CombinedState = "NOT_RUN" :: TestState
    self.ContentsState = "NORMAL" :: TestContentsState
    self.Output = {}
    self.ChildTests = {}
    self.TestAdded = self:CreateEvent()
    self.TestRemoved = self:CreateEvent()
    self.OutputAdded = self:CreateEvent()
    self.OutputCleared = self:CreateEvent()
end

--[[
Returns the full name of the test.
--]]
function Test.GetFullName(self: Test): string
    if not self.ParentTest or self.ParentTest.Hidden then
        return self.Name
    end
    return `{self.ParentTest:GetFullName()} → {self.Name}`
end

--[[
Creates an uninitialized child test.
--]]
function Test.CreateChildTest(self: Test): Test
    --Create the new test.
    local NewTest = NexusInstanceTest.new()
    NewTest.ParentTest = self
    table.insert(self.ChildTests, NewTest)
    self.TestAdded:Fire(NewTest)

    --Connect the combined state changing.
    --This event is not stored because it will be disconnected by the test on removal.
    NewTest:GetPropertyChangedSignal("CombinedState"):Connect(function()
        self:UpdateCombinedState()
    end)

    --Return the test.
    return NewTest
end

--[[
Removes a child test.
--]]
function Test.RemoveChildTest(self: Test, ChildTest: Test): ()
    local Index = table.find(self.ChildTests, ChildTest)
    if not Index then return end
    table.remove(self.ChildTests, Index)
    ChildTest:Destroy()
    self.TestRemoved:Fire(ChildTest)
    self:UpdateCombinedState()
end

--[[
Sets the state of the test.
This is intended to capture timing information.
--]]
function Test.SetState(self: Test, State: TestState): ()
    self.State = State
    if State == "NOT_RUN" then
        self.StartTime = nil
        self.EndTime = nil
    elseif State == "IN_PROGRESS" then
        self.StartTime = tick()
        self.EndTime = nil
    else
        if not self.StartTime then
            self.StartTime = tick()
        end
        self.EndTime = tick()
    end
    self:UpdateCombinedState()
end

--[[
Updates the combined state.
--]]
function Test.UpdateCombinedState(self: Test): ()
    local NewState = self.State
    for _, ChildTest in self.ChildTests do
        if UNIT_TEST_STATE_PRIORITY[ChildTest.CombinedState] < UNIT_TEST_STATE_PRIORITY[NewState] then continue end
        NewState = ChildTest.CombinedState
    end
    self.CombinedState = NewState :: TestState
end

--[[
Adds an output to the test.
--]]
function Test.AddOutput(self: Test, MessageType: Enum.MessageType, ...: any): ()
    local Output = {
        Time = tick(),
        MessageType = MessageType,
        Contents = table.pack(...),
        ContentsSize = select("#", ...), --Handles nil being part of ...
    } :: OutputEntry
    table.insert(self.Output, Output)
    self.OutputAdded:Fire(Output)
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
Recursively resets the state of the test and all child tests.
--]]
function Test.ResetTestState(self: Test): ()
    --Reset the test state.
    self:SetState("NOT_RUN")
    self.ContentsState = "NORMAL"
    table.clear(self.Output)
    self.OutputCleared:Fire()

    --Reset the test state of all child tests.
    for _, ChildTest in self.ChildTests do
        (ChildTest :: Test):ResetTestState()
    end
end

--[[
Destroys the test.
--]]
function Test.Destroy(self: Test): ()
    self.ParentTest = nil
    for _, ChildTest in self.ChildTests do
        (ChildTest :: Test):Destroy()
    end
end



return NexusInstanceTest