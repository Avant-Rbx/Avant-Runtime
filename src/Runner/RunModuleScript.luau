--Runs a test with a ModuleScript.
--!strict

local Test = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("Test"):WaitForChild("Test"))
local ModuleSandbox = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("ModuleSandbox"))
local RunWithTestEZ = require(script.Parent:WaitForChild("RunWithTestEZ"))

return function(TestInstance: Test.Test): ()
    --Set the test as NOT_RUN if there is no ModuleScript.
    local ModuleScript = TestInstance.ModuleScript
    if not ModuleScript then
        TestInstance.State = "NOT_RUN"
        return
    end

    --Run the test using the ModuleSandbox.
    local ModuleSandboxInstance = ModuleSandbox.new()
    RunWithTestEZ(TestInstance, function()
        --Require the ModuleScript.
        local ModuleResult = ModuleSandboxInstance:GetModule(ModuleScript, getfenv())
        
        --Run the ModuleScript return.
        if typeof(ModuleResult) ~= "function" then return end
        ModuleResult()
    end, ModuleSandboxInstance)
end