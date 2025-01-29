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

        afterEach(function()
            TestTest:Destroy()
        end)

        it("should return full test names.", function()
            TestTest.Name = "Test1"
            local NewTest1 = TestTest:CreateChildTest()
            NewTest1.Name = "Test2"
            local NewTest2 = NewTest1:CreateChildTest()
            NewTest2.Name = "Test3"

            expect(TestTest:GetFullName()).to.equal("Test1")
            expect(NewTest1:GetFullName()).to.equal("Test1 → Test2")
            expect(NewTest2:GetFullName()).to.equal("Test1 → Test2 → Test3")
        end)

        it("should create child tests.", function()
            local TestAddedCalls = {}
            TestTest.TestAdded:Connect(function(AddedTest)
                table.insert(TestAddedCalls, AddedTest)
            end)

            local NewTest = TestTest:CreateChildTest()
            task.wait()
            expect(NewTest.ParentTest).to.equal(TestTest)
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
            expect(#TestAddedCalls).to.equal(1)
            expect(TestAddedCalls[1]).to.equal(NewTest)
        end)

        it("should remove child tests.", function()
            local TestRemovedCalls = {}
            TestTest.TestRemoved:Connect(function(RemovedTest)
                table.insert(TestRemovedCalls, RemovedTest)
            end)

            local NewTest = TestTest:CreateChildTest()
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
            TestTest:RemoveChildTest(NewTest)
            task.wait()
            expect(NewTest.ParentTest).to.equal(nil)
            expect(TestTest.ChildTests[1]).to.equal(nil)
            expect(#TestRemovedCalls).to.equal(1)
            expect(TestRemovedCalls[1]).to.equal(NewTest)
        end)

        it("should not remove unknown child tests.", function()
            local NewTest = TestTest:CreateChildTest()
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
            NewTest:RemoveChildTest(Test.new())
            expect(TestTest.ChildTests[1]).to.equal(NewTest)
        end)

        it("should reset the start and end times.", function()
            TestTest.ContentsState = "UPDATED"
            TestTest.StartTime = tick()
            TestTest.EndTime = tick()
            TestTest:SetState("NOT_RUN")
            expect(TestTest.ContentsState).to.equal("NORMAL")
            expect(TestTest.StartTime).to.equal(nil)
            expect(TestTest.EndTime).to.equal(nil)
        end)

        it("should reset the end time.", function()
            TestTest.ContentsState = "UPDATED"
            TestTest.EndTime = tick()
            TestTest:SetState("IN_PROGRESS")
            expect(TestTest.ContentsState).to.equal("NORMAL")
            expect(TestTest.StartTime).to.never.equal(nil)
            expect(TestTest.EndTime).to.equal(nil)
        end)

        it("should store the end time.", function()
            TestTest.ContentsState = "UPDATED"
            TestTest.StartTime = 10
            TestTest:SetState("PASSED")
            expect(TestTest.ContentsState).to.equal("NORMAL")
            expect(TestTest.StartTime).to.equal(10)
            expect(TestTest.EndTime).to.never.equal(nil)
        end)

        it("should store the start and end time.", function()
            TestTest.ContentsState = "UPDATED"
            TestTest:SetState("PASSED")
            expect(TestTest.ContentsState).to.equal("NORMAL")
            expect(TestTest.StartTime).to.never.equal(nil)
            expect(TestTest.EndTime).to.never.equal(nil)
        end)

        it("should add output.", function()
            TestTest:AddOutput(Enum.MessageType.MessageWarning, "Message1", "Message2")
            expect(TestTest.Output[1].Time).to.never.equal(nil)
            expect(TestTest.Output[1].MessageType).to.equal(Enum.MessageType.MessageWarning)
            expect(#TestTest.Output[1].Contents).to.equal(2)
            expect(TestTest.Output[1].Contents[1]).to.equal("Message1")
            expect(TestTest.Output[1].Contents[2]).to.equal("Message2")
            expect(TestTest.Output[1].ContentsSize).to.equal(2)
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
            local ClearedEventCalls = 0
            TestTest.OutputCleared:Connect(function()
                ClearedEventCalls += 1
            end)

            TestTest:AddOutput(Enum.MessageType.MessageWarning, "Message1", "Message2")
            TestTest:ClearOutput()
            expect(#TestTest.Output).to.equal(0)
            task.wait()
            expect(ClearedEventCalls).to.equal(1)
        end)

        it("should update the combined state.", function()
            expect(TestTest.CombinedState).to.equal("NOT_RUN")
            TestTest:SetState("PASSED")
            expect(TestTest.CombinedState).to.equal("PASSED")

            local ChildTest = TestTest:CreateChildTest()
            expect(TestTest.CombinedState).to.equal("PASSED")
            ChildTest:SetState("IN_PROGRESS")
            task.wait()
            expect(TestTest.CombinedState).to.equal("IN_PROGRESS")
            ChildTest:SetState("FAILED")
            task.wait()
            expect(TestTest.CombinedState).to.equal("FAILED")
            ChildTest:SetState("PASSED")
            task.wait()
            expect(TestTest.CombinedState).to.equal("PASSED")

            TestTest:SetState("FAILED")
            expect(TestTest.CombinedState).to.equal("FAILED")
        end)
    end)
end