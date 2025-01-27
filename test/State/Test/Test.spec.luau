--Tests Test.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Test = require(ReplicatedStorage.AvantRuntime.State.Test.Test)

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

        it("should add output.", function()
            TestTest:AddOutput(Enum.MessageType.MessageWarning, "Message1", "Message2")
            expect(TestTest.Output[1].Time).to.never.equal(nil)
            expect(TestTest.Output[1].MessageType).to.equal(Enum.MessageType.MessageWarning)
            expect(#TestTest.Output[1].Contents).to.equal(2)
            expect(TestTest.Output[1].Contents[1]).to.equal("Message1")
            expect(TestTest.Output[1].Contents[2]).to.equal("Message2")
        end)

        it("should add output to the right test.", function()
            local function Print()
                Test.new():AddOutputForCall(Enum.MessageType.MessageWarning, "Message1", "Message2")
            end

            local function EnvironmentCall()
                Print()
            end

            local Environment = setmetatable({
                AddTestOutput = function(...)
                    TestTest:AddOutput(...)
                end,
                RunTestFunctionHash = tostring(EnvironmentCall)
            }, {__index = getfenv()})
            setfenv(EnvironmentCall, Environment :: any)
            EnvironmentCall()

            expect(TestTest.Output[1].MessageType).to.equal(Enum.MessageType.MessageWarning)
            expect(#TestTest.Output[1].Contents).to.equal(2)
            expect(TestTest.Output[1].Contents[1]).to.equal("Message1")
            expect(TestTest.Output[1].Contents[2]).to.equal("Message2")
        end)

        it("should clear the output.", function()
            TestTest:AddOutput(Enum.MessageType.MessageWarning, "Message1", "Message2")
            TestTest:ClearOutput()
            expect(#TestTest.Output).to.equal(0)
        end)
    end)
end