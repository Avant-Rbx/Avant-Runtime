--Context for managing subtests.
--To try to reduce UI refreshes and make the output easier to reload, old child tests are re-used when possible.
--!strict

local Test = require(script.Parent:WaitForChild("Test"))

local TestRunContext = {}
TestRunContext.__index = TestRunContext

export type TestRunContext = {
    NextTestIndex: number,
    ParentTest: Test.Test,
    UnusedChildTests: {Test.Test},
} & typeof(setmetatable({}, TestRunContext))



--[[
Creates a parent test.
--]]
function TestRunContext.new(ParentTest: Test.Test): TestRunContext
    --Copy the list of child tests.
    --When possible, these are re-used, but a previous list is required to handle duplicates.
    local UnusedChildTests = {}
    for _, ChildTest in ParentTest.ChildTests do
        table.insert(UnusedChildTests, ChildTest)
    end

    --Create and return the object.
    return setmetatable({
        NextTestIndex = 0,
        ParentTest = ParentTest,
        UnusedChildTests = UnusedChildTests,
    }, TestRunContext) :: TestRunContext
end

--[[
Prepares the child tests to be run.
--]]
function TestRunContext.PrepareChildTests(self: TestRunContext): ()
    --Increase the order for all tests and set them as NOTRUN.
    --Increasing the order is done to allow for easy insertion of new tests.
    for _, ChildTest in self.UnusedChildTests do
        ChildTest.SortIndex += 1000000
        ChildTest.State = "NOTRUN"
        ChildTest:ClearOutput()
    end
end

--[[
Creates or returns a test with a matching name.
--]]
function TestRunContext.GetTest(self: TestRunContext, Name: string): Test.Test
    self.NextTestIndex += 1

    --Find the next unused test that matches the name.
    for i = 1, #self.UnusedChildTests do
        local ChildTest = self.UnusedChildTests[i]
        if ChildTest.Name ~= Name then continue end
        table.remove(self.UnusedChildTests, i)
        ChildTest.SortIndex = self.NextTestIndex
        return ChildTest
    end

    --Create and return a new test.
    local NewTest = self.ParentTest:CreateChildTest()
    NewTest.Name = Name
    NewTest.SortIndex = self.NextTestIndex
    return NewTest
end

--[[
Clears any unused child tests.
--]]
function TestRunContext.ClearUnusedChildTests(self: TestRunContext): ()
    for _, ChildTest in self.UnusedChildTests do
        self.ParentTest:RemoveChildTest(ChildTest)
    end
    self.UnusedChildTests = {}
end



return TestRunContext