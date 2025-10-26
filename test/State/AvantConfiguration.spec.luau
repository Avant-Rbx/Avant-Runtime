--Tests AvantConfiguration.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AvantConfiguration = require(ReplicatedStorage.Packages.AvantRuntime.State.AvantConfiguration)

return function()
    describe("A AvantConfiguration", function()
        local TestContainer, TestStringValue1, TestStringValue2 = nil, nil, nil
        local ChangedCalls = 0
        local TestConfiguration = nil
        beforeEach(function()
            TestContainer = Instance.new("Folder")

            TestStringValue1 = Instance.new("StringValue")
            TestStringValue1.Name = "AvantIgnoredPaths"
            TestStringValue1.Value = "[\"Value1\",\"Value2\"]"
            TestStringValue1.Parent = TestContainer

            TestStringValue2 = Instance.new("StringValue")
            TestStringValue2.Name = "UnknownName"
            TestStringValue2.Value = "[\"Value3\",\"Value4\"]"
            TestStringValue2.Parent = TestContainer

            TestConfiguration = AvantConfiguration.new(TestContainer)

            TestConfiguration.ConfigurationChanged:Connect(function()
                ChangedCalls += 1
            end)
        end)

        afterEach(function()
            ChangedCalls = 0
            TestConfiguration:Destroy()
        end)

        it("should connect existing StringValues.", function()
            expect(TestConfiguration:IsIgnored("Value1")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(false)
            expect(ChangedCalls).to.equal(0)

            TestStringValue1.Value = "[\"Value2\",\"Value3\"]"
            task.wait()
            expect(TestConfiguration:IsIgnored("Value1")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(false)
            expect(ChangedCalls).to.equal(1)
        end)

        it("should connect renamed StringValues.", function()
            TestStringValue2.Name = "AvantIgnoredPaths"
            task.wait()
            expect(TestConfiguration:IsIgnored("Value1")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(true)
            expect(ChangedCalls).to.equal(1)

            TestStringValue2.Name = "UnknownName"
            task.wait()
            expect(TestConfiguration:IsIgnored("Value1")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(false)
            expect(ChangedCalls).to.equal(2)
        end)

        it("should connect new StringValues.", function()
            local NewStringValue = Instance.new("StringValue")
            NewStringValue.Name = "AvantIgnoredPaths"
            NewStringValue.Value = "[\"Value5\",\"Value6\"]"
            NewStringValue.Parent = TestContainer
            task.wait()

            expect(TestConfiguration:IsIgnored("Value1")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value5")).to.equal(true)
            expect(TestConfiguration:IsIgnored("Value6")).to.equal(true)
            expect(ChangedCalls).to.equal(1)
        end)

        it("should handle removed StringValues.", function()
            TestStringValue1:Destroy()
            task.wait()

            expect(TestConfiguration:IsIgnored("Value1")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value2")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value3")).to.equal(false)
            expect(TestConfiguration:IsIgnored("Value4")).to.equal(false)
            expect(ChangedCalls).to.equal(1)
        end)
    end)
end