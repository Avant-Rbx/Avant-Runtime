--Discovers and tracks ModuleScripts with tests.
--!strict

local ModuleScriptMonitor = require(script.Parent:WaitForChild("ModuleScriptMonitor"))
local Test = require(script.Parent.Parent:WaitForChild("Test"):WaitForChild("Test"))

local ModuleScriptDiscovery = {}
ModuleScriptDiscovery.__index = ModuleScriptDiscovery

export type ModuleScriptDiscovery = {
    Container: Instance,
    RootTest: Test.Test,
    Monitors: {[ModuleScript]: ModuleScriptMonitor.ModuleScriptMonitor},
    EventConnections: {RBXScriptConnection},
} & typeof(setmetatable({}, ModuleScriptDiscovery))



--[[
Creates a ModuleScript discovery tracker for a container.
--]]
function ModuleScriptDiscovery.new(Container: Instance): ModuleScriptDiscovery
    --Create the object.
    local self = setmetatable({
        Container = Container,
        RootTest = Test.new(),
        Monitors = {},
        EventConnections = {},
    }, ModuleScriptDiscovery) :: ModuleScriptDiscovery

    --Connect ModuleScripts being added.
    table.insert(self.EventConnections, Container.DescendantAdded:Connect(function(Child)
        self:TrackModuleScript(Child)
    end))
    for _, Child in Container:GetDescendants() do
        self:TrackModuleScript(Child)
    end

    --Return the object.
    return self
end

--[[
Tracks a ModuleScript.
--]]
function ModuleScriptDiscovery.TrackModuleScript(self: ModuleScriptDiscovery, ModuleScript: Instance): ()
    --Return if the instance can't be tracked.
    local Worked, CanBeTracked = pcall(function()
        return ModuleScript:IsA("ModuleScript")
    end)
    if not Worked or not CanBeTracked then return end

    --Create the ModuleScript monitor.
    if self.Monitors[ModuleScript :: ModuleScript] then return end
    self.Monitors[ModuleScript :: ModuleScript] = ModuleScriptMonitor.new(ModuleScript :: ModuleScript, self.Container, self.RootTest)
end

--[[
Destroys the ModuleScript discovery.
--]]
function ModuleScriptDiscovery.Destroy(self: ModuleScriptDiscovery): ()
    --Clear the event connections.
    for _, EventConnection in self.EventConnections do
        EventConnection:Disconnect()
    end
    self.EventConnections = {}

    --Clear the ModuleScript monitors.
    for _, Monitor in self.Monitors do
        (Monitor :: ModuleScriptMonitor.ModuleScriptMonitor):Destroy()
    end
    self.Monitors = {}

    --Clear the tests.
    self.RootTest:Destroy()
end



return ModuleScriptDiscovery