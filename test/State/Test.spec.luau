--Tests Test.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Test = require(ReplicatedStorage.AvantRuntime.State.Test)

return function()
    describe("A Test", function()
        local TestTest = nil
        beforeEach(function()
            TestTest = Test.new()
        end)

        it("should create child tests.", function()
            local NewTest = TestTest:CreateChildTest()
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
        end)

        it("should remove child tests.", function()
            local NewTest = TestTest:CreateChildTest()
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
            TestTest:RemoveChildTest(NewTest)
            expect(TestTest.ChildTests[1]).to.equal(nil)
        end)

        it("should not remove unknown child tests.", function()
            local NewTest = TestTest:CreateChildTest()
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
            NewTest:RemoveChildTest(Test.new())
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
        end)
    end)
end