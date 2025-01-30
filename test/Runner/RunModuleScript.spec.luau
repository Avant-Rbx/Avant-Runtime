--Tests RunModuleScript.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Test = require(ReplicatedStorage.AvantRuntime.State.Test.Test)
local RunModuleScript = require(ReplicatedStorage.AvantRuntime.Runner.RunModuleScript)

return function()
    describe("The RunModuleScript function", function()
        local TestTest = nil
        beforeEach(function()
            TestTest = Test.new()
            TestTest.State = "SKIPPED"
        end)

        afterEach(function()
            TestTest:Destroy()
        end)

        it("should not with no ModuleScript.", function()
            RunModuleScript(TestTest)
            expect(TestTest.State).to.equal("NOT_RUN")
        end)

        it("should run ModuleScripts with TestEZ.", function()
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = [[print("Test print 1")
            return function()
                print("Test print 2")
                describe("A test", function()
                    print("Test print 3")
                    it("should print to the correct test.", function()
                        print("Test print 4")
                    end)

                    it("should fail.", function()
                        error("Test error")
                    end)
                end)
            end]]
            TestTest.ModuleScript = ModuleScript

            RunModuleScript(TestTest)
            expect(TestTest.State).to.equal("PASSED")
            expect(#TestTest.Output).to.equal(2)
            expect(TestTest.Output[1].Contents[1]).to.equal("Test print 1")
            expect(TestTest.Output[2].Contents[1]).to.equal("Test print 2")
            expect(#TestTest.ChildTests).to.equal(1)
            expect(TestTest.ChildTests[1].Name).to.equal("A test")
            expect(TestTest.ChildTests[1].State).to.equal("PASSED")
            expect(TestTest.ChildTests[1].Output[1].Contents[1]).to.equal("Test print 3")
            expect(#TestTest.ChildTests[1].ChildTests).to.equal(2)
            expect(TestTest.ChildTests[1].ChildTests[1].Name).to.equal("should print to the correct test.")
            expect(TestTest.ChildTests[1].ChildTests[1].State).to.equal("PASSED")
            expect(TestTest.ChildTests[1].ChildTests[1].Output[1].Contents[1]).to.equal("Test print 4")
            expect(TestTest.ChildTests[1].ChildTests[2].Name).to.equal("should fail.")
            expect(TestTest.ChildTests[1].ChildTests[2].State).to.equal("FAILED")
        end)

        it("should run ModuleScripts without function returns.", function()
            local ModuleScript = Instance.new("ModuleScript")
            ModuleScript.Source = "print(\"Test print 1\") return true"
            TestTest.ModuleScript = ModuleScript

            RunModuleScript(TestTest)
            expect(TestTest.State).to.equal("PASSED")
            expect(#TestTest.Output).to.equal(1)
            expect(TestTest.Output[1].Contents[1]).to.equal("Test print 1")
            expect(#TestTest.ChildTests).to.equal(0)
        end)

        it("should capture print statements from modules.", function()
            local ModuleScript1 = Instance.new("ModuleScript")
            ModuleScript1.Source = "print(\"Test print 1\") return require(script.ModuleScript)"
            TestTest.ModuleScript = ModuleScript1
            
            local ModuleScript2 = Instance.new("ModuleScript")
            ModuleScript2.Source = "print(\"Test print 2\") return true"
            ModuleScript2.Parent = ModuleScript1

            RunModuleScript(TestTest)
            expect(TestTest.State).to.equal("PASSED")
            expect(#TestTest.Output).to.equal(2)
            expect(TestTest.Output[1].Contents[1]).to.equal("Test print 1")
            expect(TestTest.Output[2].Contents[1]).to.equal("Test print 2")
            expect(#TestTest.ChildTests).to.equal(0)
        end)
    end)
end