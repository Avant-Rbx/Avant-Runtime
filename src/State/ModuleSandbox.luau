--Sandboxes requiring ModuleScripts to prevent caching and tests interferring with each other with different requires.
--A sandbox can have child versions that have independently loaded versions.
--!strict

local ScriptEditorService = game:GetService("ScriptEditorService")

local ModuleSandbox = {}
ModuleSandbox.__index = ModuleSandbox

export type ModuleSandbox = {
    ParentSandbox: ModuleSandbox?,
    EnvironmentOverrides: {[string]: any},
    ModuleLookup: {[ModuleScript]: ModuleScript},
} & typeof(setmetatable({}, ModuleSandbox))



--[[
Creates a module sandbox.
--]]
function ModuleSandbox.new(ParentSandbox: ModuleSandbox?): ModuleSandbox
    --Create the object.
    local self = setmetatable({
        ParentSandbox = ParentSandbox,
        EnvironmentOverrides = {
            plugin = plugin,
        },
        ModuleLookup = {},
    }, ModuleSandbox) :: ModuleSandbox

    --Prepare the environment metatable.
    if ParentSandbox then
        setmetatable(self.EnvironmentOverrides, {__index = ParentSandbox.EnvironmentOverrides})
    else
        setmetatable(self.EnvironmentOverrides, {__index = getfenv()})
    end
    self.EnvironmentOverrides["require"] = function(ModuleScript: ModuleScript): any
        return self:GetModule(ModuleScript)
    end
    self.EnvironmentOverrides["loadstring"] = function(...): any
        local LoadedFunction = loadstring(...) :: any
        setfenv(LoadedFunction, getfenv(debug.info(coroutine.running(), 2, "f")))
        return LoadedFunction
    end

    --Return the object.
    return self
end

--[[
Returns a loaded module if it was required already.
If the module has not been loaded, it will not be required.
This will yield if the module is still loading from a previous require.
--]]
function ModuleSandbox.GetModuleIfLoaded(self: ModuleSandbox, Module: ModuleScript): any?
    --Return the parent sandbox result if the module wasn't loaded.
    local ExistingModule = self.ModuleLookup[Module] :: ModuleScript?
    if self.ParentSandbox and ExistingModule == nil then
        return self.ParentSandbox:GetModuleIfLoaded(Module)
    end

    --Return the loaded contents.
    return ExistingModule and require(ExistingModule) :: any
end

--[[
Requires a module.
--]]
function ModuleSandbox.GetModule(self: ModuleSandbox, Module: ModuleScript, EnvironmentOverrides: {[string]: any}?): any
    --Return the existing result.
    local ExistingModuleContents = self:GetModuleIfLoaded(Module)
    if ExistingModuleContents ~= nil then
        return ExistingModuleContents
    end

    --Throw an error if it isn't a ModuleScript.
    if typeof(Module) ~= "Instance" or not Module:IsA("ModuleScript") then
        error(`{Module} is not a ModuleScript.`)
    end

    --Prepare the environment.
    local Environment = setmetatable({
        script = Module,
    }, {__index = self.EnvironmentOverrides})
    if EnvironmentOverrides then
        for Key, Value in EnvironmentOverrides do
            Environment[Key] = Value
        end
    end

    --Clone and modify the ModuleScipt.
    local IsArchivable = Module.Archivable
    Module.Archivable = true
    local ClonedModule = Module:Clone()
    _G[ClonedModule] = Environment
    ClonedModule.Source = `local function Load() {ScriptEditorService:GetEditorSource(Module)}\nend\n\nsetfenv(Load, _G[script])\n_G[script] = nil\nreturn Load()`
    Module.Archivable = IsArchivable
    ClonedModule.Archivable = IsArchivable
    self.ModuleLookup[Module] = ClonedModule

    --Return the module.
    --require is returned to allow for errors to be passed.
    return require(self.ModuleLookup[Module]) :: any
end

--[[
Destroys the module sandbox.
--]]
function ModuleSandbox.Destroy(self: ModuleSandbox): ()
    self.ModuleLookup = {}
end



return ModuleSandbox