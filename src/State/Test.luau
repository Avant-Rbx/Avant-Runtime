--State for a test, including sub-tests.
--!strict

local Test = {}
Test.__index = Test

export type TestState = "NOTRUN" | "INPROGRESS" | "PASSED" | "FAILED" | "SKIPPED"
export type TestContentsState = "NORMAL" | "UPDATED" | "MISSING"
export type OutputEntry = {
    MessageType: Enum.MessageType,
    Contents: any,
}
export type Test = {
    Name: string,
    SortIndex: number,
    State: TestState,
    ContentsState: TestContentsState,
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
Removes a child test.
--]]
function Test.RemoveChildTest(self: Test, ChildTest: Test): ()
    local Index = table.find(self.ChildTests, ChildTest)
    if not Index then return end
    table.remove(self.ChildTests, Index)
end



return Test