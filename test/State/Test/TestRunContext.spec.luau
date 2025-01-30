--Tests TestRunContext.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestRunContext = require(ReplicatedStorage.AvantRuntime.State.Test.TestRunContext)
local Test = require(ReplicatedStorage.AvantRuntime.State.Test.Test)

return function()
    describe("A TestRunContext", function()
        local TestTestRunContext = nil
        local TestTest = nil
        beforeEach(function()
            TestTest = Test.new()

            local Test1 = TestTest:CreateChildTest()
            Test1.SortIndex = 1
            Test1.Name = "Test1"

            local Test2 = TestTest:CreateChildTest()
            Test2.SortIndex = 2
            Test2.Name = "Test2"

            local Test3 = TestTest:CreateChildTest()
            Test3.SortIndex = 3
            Test3.Name = "Test2"

            TestTestRunContext = TestRunContext.new(TestTest)
        end)

        afterEach(function()
            TestTest:Destroy()
        end)

        it("should prepare tests.", function()
            TestTestRunContext:PrepareChildTests()
            expect(#TestTestRunContext.UnusedChildTests).to.equal(3)
            expect(TestTestRunContext.UnusedChildTests[1].Name).to.equal("Test1")
            expect(TestTestRunContext.UnusedChildTests[1].SortIndex).to.equal(1000001)
            expect(TestTestRunContext.UnusedChildTests[2].Name).to.equal("Test2")
            expect(TestTestRunContext.UnusedChildTests[2].SortIndex).to.equal(1000002)
            expect(TestTestRunContext.UnusedChildTests[3].Name).to.equal("Test2")
            expect(TestTestRunContext.UnusedChildTests[3].SortIndex).to.equal(1000003)
        end)

        it("should use existing tests.", function()
            TestTestRunContext:PrepareChildTests()

            local ChildTest = TestTestRunContext:GetTest("Test1")
            expect(ChildTest.Name).to.equal("Test1")
            expect(ChildTest.SortIndex).to.equal(1)

            expect(#TestTestRunContext.UnusedChildTests).to.equal(2)
            expect(TestTestRunContext.UnusedChildTests[1].Name).to.equal("Test2")
            expect(TestTestRunContext.UnusedChildTests[1].SortIndex).to.equal(1000002)
            expect(TestTestRunContext.UnusedChildTests[2].Name).to.equal("Test2")
            expect(TestTestRunContext.UnusedChildTests[2].SortIndex).to.equal(1000003)
        end)

        it("should use existing duplicate tests.", function()
            TestTestRunContext:PrepareChildTests()

            local ChildTest1 = TestTestRunContext:GetTest("Test2")
            local ChildTest2 = TestTestRunContext:GetTest("Test2")
            expect(ChildTest1.Name).to.equal("Test2")
            expect(ChildTest1.SortIndex).to.equal(1)
            expect(ChildTest2.Name).to.equal("Test2")
            expect(ChildTest2.SortIndex).to.equal(2)
            expect(#TestTestRunContext.UnusedChildTests).to.equal(1)
            expect(TestTestRunContext.UnusedChildTests[1].Name).to.equal("Test1")
            expect(TestTestRunContext.UnusedChildTests[1].SortIndex).to.equal(1000001)
        end)

        it("should create new tests.", function()
            TestTestRunContext:PrepareChildTests()

            local ChildTest1 = TestTestRunContext:GetTest("Test4")
            local ChildTest2 = TestTestRunContext:GetTest("Test5")
            expect(ChildTest1.Name).to.equal("Test4")
            expect(ChildTest1.SortIndex).to.equal(1)
            expect(ChildTest2.Name).to.equal("Test5")
            expect(ChildTest2.SortIndex).to.equal(2)
            expect(#TestTestRunContext.UnusedChildTests).to.equal(3)
        end)
    end)
end