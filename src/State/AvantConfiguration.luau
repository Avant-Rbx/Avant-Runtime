--Reads and caches the instance-based configuration for Avant.
--!strict

local HttpService = game:GetService("HttpService")

local NexusInstance = require(script.Parent.Parent:WaitForChild("Packages"):WaitForChild("NexusInstance"))

local AvantConfiguration = {}
AvantConfiguration._StaticInstance = nil :: AvantConfiguration?
AvantConfiguration.__index = AvantConfiguration

export type AvantConfiguration = {
    ConfigurationChanged: NexusInstance.TypedEvent<>,
    _IgnoredPaths: {[StringValue]: {string}},
    _EventConnections: {RBXScriptConnection},
    _StringValueEventConnections: {[StringValue]: {RBXScriptConnection}},
} & typeof(setmetatable({}, AvantConfiguration))



--[[
Creates a configuration with an optional container to track instances in.
--]]
function AvantConfiguration.new(Container: Instance?): AvantConfiguration
    --Create the object.
    local self = setmetatable({
        ConfigurationChanged = NexusInstance.TypedEvent.new(),
        _IgnoredPaths = {},
        _EventConnections = {},
        _StringValueEventConnections = {},
    }, AvantConfiguration) :: AvantConfiguration

    --Track StringValues being added.
    local CurrentContainer = Container or game
    for _, Child in CurrentContainer:GetDescendants() do
        self:_TrackStringValue(Child)
    end
    table.insert(self._EventConnections, CurrentContainer.DescendantAdded:Connect(function(Child)
        self:_TrackStringValue(Child)
    end))

    --Track being removed.
    table.insert(self._EventConnections, CurrentContainer.DescendantRemoving:Connect(function(Child)
        --Clear the event connections.
        if not self._StringValueEventConnections[Child] then return end
        for _, EventConnection in self._StringValueEventConnections[Child] do
            EventConnection:Disconnect()
        end
        self._StringValueEventConnections[Child] = nil

        --Clear the configuration.
        if not self._IgnoredPaths[Child] then return end
        self._IgnoredPaths[Child] = nil
        self.ConfigurationChanged:Fire()
    end))
    

    --Return the object.
    return self
end

--[[
Returns a static instance of the configuration.
--]]
function AvantConfiguration.GetInstance(): AvantConfiguration
    if not AvantConfiguration._StaticInstance then
        AvantConfiguration._StaticInstance = AvantConfiguration.new()
    end
    return AvantConfiguration._StaticInstance :: AvantConfiguration
end

--[[
Returns if an instance path is ignored.
--]]
function AvantConfiguration.IsIgnored(self: AvantConfiguration, Path: string): boolean
    for _, Paths in self._IgnoredPaths do
        for _, IgnoredPath in Paths do
            if not string.find(Path, IgnoredPath) then continue end
            return true
        end
    end
    return false
end

--[[
Tracks a StringValue.
--]]
function AvantConfiguration._TrackStringValue(self: AvantConfiguration, Ins: Instance): ()
    --Return if it the provided instance is not a StringValue.
    --This is done in a pcall in case a protected instance is checked.
    local Worked, IsStringValue = pcall(function()
        return Ins:IsA("StringValue")
    end)
    if not Worked or not IsStringValue then return end
    local StringValue = Ins :: StringValue

    --Track changes to the StringValue.
    if self._StringValueEventConnections[StringValue] then return end
    local StringValueEventConnections = {}
    self._StringValueEventConnections[StringValue] = StringValueEventConnections
    for _, PropertyName in {"Name", "Value"} do
        table.insert(StringValueEventConnections, StringValue:GetPropertyChangedSignal(PropertyName):Connect(function()
            self:_UpdateFromStringValue(StringValue)
        end))
    end
    self:_UpdateFromStringValue(StringValue)
end

--[[
Updates the state from a StringValue.
--]]
function AvantConfiguration._UpdateFromStringValue(self: AvantConfiguration, StringValue: StringValue): ()
    --Unset any stored values.
    local HadValues = false
    if self._IgnoredPaths[StringValue] then
        HadValues = true
        self._IgnoredPaths[StringValue] = nil
    end

    --Handle the updated value.
    local UpdatedValues = false
    if StringValue.Name == "AvantIgnoredPaths" then
        xpcall(function()
            UpdatedValues = true
            self._IgnoredPaths[StringValue] = HttpService:JSONDecode(StringValue.Value)
        end, function(ErrorMessage)
            warn(`Failed to parse {StringValue:GetFullName()}: {ErrorMessage}`)
        end)
    end

    --Fire the changed event.
    if not HadValues and not UpdatedValues then return end
    self.ConfigurationChanged:Fire()
end

--[[
Destroys the configuration.
--]]
function AvantConfiguration.Destroy(self: AvantConfiguration): ()
    --Clear the events.
    self.ConfigurationChanged:Destroy()
    for _, EventConnection in self._EventConnections do
        EventConnection:Disconnect()
    end
    table.clear(self._EventConnections)

    --Clear the StringValues.
    for _, EventConnections in self._StringValueEventConnections do
        for _, EventConnection in EventConnections do
            EventConnection:Disconnect()
        end
    end
    table.clear(self._StringValueEventConnections)
    table.clear(self._IgnoredPaths)
end



return AvantConfiguration