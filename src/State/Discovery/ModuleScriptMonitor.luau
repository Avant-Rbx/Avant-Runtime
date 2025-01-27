--Monitors a ModuleScript and updates the test state.
--!strict

local Test = require(script.Parent.Parent:WaitForChild("Test"):WaitForChild("Test"))

local ModuleScriptMonitor = {}
ModuleScriptMonitor.__index = ModuleScriptMonitor

export type ModuleScriptMonitor = {
    ModuleScript: ModuleScript,
    Container: Instance,
    ParentTest: Test.Test,
    CurrentTest: Test.Test?,
    EventConnections: {RBXScriptConnection},
} & typeof(setmetatable({}, ModuleScriptMonitor))



--[[
Creates a ModuleScript monitor.
--]]
function ModuleScriptMonitor.new(ModuleScript: ModuleScript, Container: Instance, ParentTest: Test.Test): ModuleScriptMonitor
    --Create the object.
    local self = setmetatable({
        ModuleScript = ModuleScript,
        Container = Container,
        ParentTest = ParentTest,
        EventConnections = {},
    }, ModuleScriptMonitor) :: ModuleScriptMonitor

    --Track changes to the script.
    table.insert(self.EventConnections, ModuleScript:GetPropertyChangedSignal("Name"):Connect(function()
        self:UpdateTest("Name")
    end))
    table.insert(self.EventConnections, ModuleScript:GetPropertyChangedSignal("Source"):Connect(function()
        self:UpdateTest("Source")
    end))
    table.insert(self.EventConnections, ModuleScript.AncestryChanged:Connect(function()
        self:UpdateTest("Parent")
    end))
    self:UpdateTest("Create")

    --Return the object.
    return self
end

--[[
Updates the stored test for the ModuleScript.
--]]
function ModuleScriptMonitor.UpdateTest(self: ModuleScriptMonitor, UpdateSource: "Name" | "Source" | "Parent" | "Create"): ()
    --Determine if the ModuleScript is a supported test.
    local IsValidTest = false
    if self.ModuleScript:IsDescendantOf(self.Container) and self.ModuleScript.Name:match("%.spec$") then
        IsValidTest = true
    end

    --Mark the test as missing if it is no longer valid.
    if not IsValidTest then
        if self.CurrentTest then
            self.CurrentTest.ContentsState = "MISSING"
            self.CurrentTest.ModuleScript = nil
            if self.CurrentTest.State == "NOTRUN" then
                self.ParentTest:RemoveChildTest(self.CurrentTest)
                self.CurrentTest = nil
            end
        end
        return
    end

    --Create the test if it doesn't exist.
    if not self.CurrentTest then
        self.CurrentTest = self.ParentTest:CreateChildTest()
    end

    --Update the test state.
    local CurrentTest = self.CurrentTest :: Test.Test
    CurrentTest.Name = self.ModuleScript:GetFullName()
    CurrentTest.ModuleScript = self.ModuleScript
    if UpdateSource == "Create" or UpdateSource == "Source" then
        CurrentTest.ContentsState = "UPDATED"
    end
end

--[[
Destroys the ModuleScript monitor.
--]]
function ModuleScriptMonitor.Destroy(self: ModuleScriptMonitor): ()
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}
end



return ModuleScriptMonitor