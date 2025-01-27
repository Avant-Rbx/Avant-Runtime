--Tests ModuleScriptMonitor.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleScriptMonitor = require(ReplicatedStorage.AvantRuntime.State.Discovery.ModuleScriptMonitor)
local Test = require(ReplicatedStorage.AvantRuntime.State.Test)

return function()
    describe("A ModuleScriptMonitor", function()
        local TestModuleScriptMonitor = nil
        local TestParentTest, TestFolder1, TestFolder2, TestFolder3, TestModuleScript = nil, nil, nil, nil, nil
        beforeEach(function()
            TestFolder1 = Instance.new("Folder")
            TestFolder1.Name = "TestFolder1"
            
            TestFolder2 = Instance.new("Folder")
            TestFolder2.Name = "TestFolder2"
            TestFolder2.Parent = TestFolder1

            TestFolder3 = Instance.new("Folder")
            TestFolder3.Name = "TestFolder3"

            TestModuleScript = Instance.new("ModuleScript")
            TestModuleScript.Name = "ModuleScript.spec"
            TestModuleScript.Parent = TestFolder1

            TestParentTest = Test.new()

            TestModuleScriptMonitor = ModuleScriptMonitor.new(TestModuleScript, TestFolder1, TestParentTest)
        end)

        afterEach(function()
            TestModuleScriptMonitor:Destroy()
            TestFolder1:Destroy()
            TestFolder2:Destroy()
            TestModuleScript:Destroy()
        end)

        it("should create the initial test.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            expect(CurrentTest.Name).to.equal("TestFolder1.ModuleScript.spec")
            expect(CurrentTest.ContentsState).to.equal("UPDATED")
            expect(#TestParentTest.ChildTests).to.equal(1)
            expect(TestParentTest.ChildTests[1]).to.equal(CurrentTest)
        end)

        it("should update the name and not update the contents state.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            CurrentTest.ContentsState = "NORMAL"
            TestModuleScript.Name = "ModuleScript2.spec"
            task.wait()
            expect(CurrentTest.Name).to.equal("TestFolder1.ModuleScript2.spec")
            expect(CurrentTest.ContentsState).to.equal("NORMAL")
        end)

        it("should update the parent and not update the contents state.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            CurrentTest.ContentsState = "NORMAL"
            TestModuleScript.Parent = TestFolder2
            task.wait()
            expect(CurrentTest.Name).to.equal("TestFolder1.TestFolder2.ModuleScript.spec")
            expect(CurrentTest.ContentsState).to.equal("NORMAL")
        end)

        it("should update the contents.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            CurrentTest.ContentsState = "NORMAL"
            TestModuleScript.Source = "NewSource"
            task.wait()
            expect(CurrentTest.Name).to.equal("TestFolder1.ModuleScript.spec")
            expect(CurrentTest.ContentsState).to.equal("UPDATED")
        end)

        it("should update when removed from the container and previously ran.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            CurrentTest.State = "PASSED"
            TestModuleScript.Parent = TestFolder3
            task.wait()
            expect(CurrentTest.Name).to.equal("TestFolder1.ModuleScript.spec") --Missing script names aren't updated.
            expect(CurrentTest.ContentsState).to.equal("MISSING")
            expect(TestParentTest.ChildTests[1]).to.equal(CurrentTest)
        end)

        it("should update when removed from the container and not previously ran.", function()
            TestModuleScript.Parent = TestFolder3
            task.wait()
            expect(TestModuleScriptMonitor.CurrentTest).to.equal(nil)
            expect(TestParentTest.ChildTests[1]).to.equal(nil)
        end)

        it("should update when renamed from a test name and previously ran.", function()
            local CurrentTest = TestModuleScriptMonitor.CurrentTest :: Test.Test
            CurrentTest.State = "PASSED"
            TestModuleScript.Name = "ModuleScript"
            task.wait()
            expect(CurrentTest.Name).to.equal("TestFolder1.ModuleScript.spec") --Missing script names aren't updated.
            expect(CurrentTest.ContentsState).to.equal("MISSING")
            expect(TestParentTest.ChildTests[1]).to.equal(CurrentTest)
        end)

        it("should update when renamed from a test name and not previously ran.", function()
            TestModuleScript.Name = "ModuleScript"
            task.wait()
            expect(TestModuleScriptMonitor.CurrentTest).to.equal(nil)
            expect(TestParentTest.ChildTests[1]).to.equal(nil)
        end)
    end)
end