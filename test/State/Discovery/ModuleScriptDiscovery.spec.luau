--Tests ModuleScriptDiscovery.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptDiscovery = require(ReplicatedStorage.AvantRuntime.State.Discovery.ModuleScriptDiscovery)

return function()
    describe("A ModuleScriptDiscovery", function()
        local TestFolder, TestModuleScript = nil, nil
        local TestModuleScriptDiscovery = nil
        beforeEach(function()
            TestFolder = Instance.new("Folder")

            TestModuleScript = Instance.new("ModuleScript")
            TestModuleScript.Parent = TestFolder

            TestModuleScriptDiscovery = ModuleScriptDiscovery.new(TestFolder)
        end)

        afterEach(function()
            TestFolder:Destroy()
            TestModuleScriptDiscovery:Destroy()
        end)

        it("should monitor existing instances.", function()
            expect(TestModuleScriptDiscovery.Monitors[TestModuleScript]).to.never.equal(nil)
        end)

        it("should monitor new ModuleScripts.", function()
            local NewModuleScript = Instance.new("ModuleScript")
            NewModuleScript.Parent = TestFolder
            task.wait()
            expect(TestModuleScriptDiscovery.Monitors[NewModuleScript]).to.never.equal(nil)
        end)

        it("should not monitor non-ModuleScripts.", function()
            local NewPart = Instance.new("Part")
            NewPart.Parent = TestFolder
            task.wait()
            expect(TestModuleScriptDiscovery.Monitors[NewPart :: any]).to.equal(nil)
        end)
    end)
end