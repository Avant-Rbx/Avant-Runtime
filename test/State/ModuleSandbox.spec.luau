--Tests ModuleSandbox.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleSandbox = require(ReplicatedStorage.AvantRuntime.State.ModuleSandbox)

return function()
    describe("A ModuleSandbox", function()
        local TestParentModuleSandbox, TestChildModuleSandbox = nil, nil
        beforeEach(function()
            TestParentModuleSandbox = ModuleSandbox.new()
            TestChildModuleSandbox = ModuleSandbox.new(TestParentModuleSandbox)
        end)

        afterEach(function()
            TestChildModuleSandbox:Destroy()
            TestParentModuleSandbox:Destroy()
        end)

        it("should cache ModuleScripts.", function()
            TestChildModuleSandbox.EnvironmentOverrides["TestValue"] = 3
            TestChildModuleSandbox.EnvironmentOverrides["TestValue"] = 5

            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return {script = script, getfenv = getfenv, TestValue = TestValue}"

            local Result = TestChildModuleSandbox:GetModule(ModuleScript)
            expect(Result.script).to.equal(ModuleScript)
            expect(Result.getfenv).to.equal(getfenv) --getfenv tests that non-overriden values still exist.
            expect(Result.TestValue).to.equal(5)

            TestChildModuleSandbox.EnvironmentOverrides["TestValue"] = 10
            local NewResult = TestChildModuleSandbox:GetModule(ModuleScript)
            expect(NewResult.script).to.equal(ModuleScript)
            expect(NewResult.getfenv).to.equal(getfenv)
            expect(NewResult.TestValue).to.equal(5)
        end)

        it("should use parent environment overrides.", function()
            TestParentModuleSandbox.EnvironmentOverrides["TestValue"] = 3

            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return TestValue"
            expect(TestChildModuleSandbox:GetModule(ModuleScript)).to.equal(3)
        end)

        it("should use cached ModuleScripts from the parent.", function()
            TestParentModuleSandbox.EnvironmentOverrides["TestValue"] = 3
            TestChildModuleSandbox.EnvironmentOverrides["TestValue"] = 5

            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return TestValue"

            expect(TestParentModuleSandbox:GetModule(ModuleScript)).to.equal(3)
            expect(TestChildModuleSandbox:GetModule(ModuleScript)).to.equal(3)
        end)

        it("should handle getting the global environment.", function()
            TestParentModuleSandbox.EnvironmentOverrides["TestValue"] = 3

            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return {getfenv(0).TestValue, getfenv().TestValue}"

            local Result = TestChildModuleSandbox:GetModule(ModuleScript)
            expect(Result[1]).to.equal(3)
            expect(Result[2]).to.equal(3)
        end)

        it("should not require non-ModuleScripts.", function()
            expect(function()
                TestChildModuleSandbox:GetModule(Instance.new("Part") :: any)
            end).to.throw("Part is not a ModuleScript.")
        end)

        it("should use environment overrides.", function()
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return TestValue"

            expect(TestChildModuleSandbox:GetModule(ModuleScript, {
                TestValue = 5
            })).to.equal(5)
        end)

        it("should handle loadstring.", function()
            TestParentModuleSandbox.EnvironmentOverrides["TestValue1"] = 3
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "return loadstring('return {TestValue1, TestValue2}')()"

            local Result = TestChildModuleSandbox:GetModule(ModuleScript, {
                TestValue2 = 5
            })
            expect(Result[1]).to.equal(3)
            expect(Result[2]).to.equal(5)
        end)

        it("should handle Archivable.", function()
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Archivable = false
            ModuleScript.Source = "return script.Archivable"

            expect(TestChildModuleSandbox:GetModule(ModuleScript)).to.equal(false)
            expect(ModuleScript.Archivable).to.equal(false)
        end)

        it("should pass require errors.", function()
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "error(\"Test error\")"

            expect(function()
                TestChildModuleSandbox:GetModule(ModuleScript)
            end).to.throw("Requested module experienced an error while loading")
        end)
    end)
end