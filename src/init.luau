--Main module for Avant Runtime.
--!strict

local RunModuleScript = require(script:WaitForChild("Runner"):WaitForChild("RunModuleScript"))
local ModuleScriptDiscovery = require(script:WaitForChild("State"):WaitForChild("Discovery"):WaitForChild("ModuleScriptDiscovery"))
local Test = require(script:WaitForChild("State"):WaitForChild("Test"):WaitForChild("Test"))
local AvantConfiguration = require(script:WaitForChild("State"):WaitForChild("AvantConfiguration"))
local ModuleSandbox = require(script:WaitForChild("State"):WaitForChild("ModuleSandbox"))
local FormatLines = require(script:WaitForChild("Util"):WaitForChild("FormatLines"))
local RunTests = require(script:WaitForChild("RunTests"))

export type AvantConfiguration = AvantConfiguration.AvantConfiguration
export type ModuleSandbox = ModuleSandbox.ModuleSandbox
export type ModuleScriptDiscovery = ModuleScriptDiscovery.ModuleScriptDiscovery

export type Test = Test.Test
export type TestState = Test.TestState
export type TestContentsState = Test.TestContentsState
export type OutputEntry = Test.OutputEntry

return {
    --Classes.
    AvantConfiguration = AvantConfiguration,
    ModuleSandbox = ModuleSandbox,
    ModuleScriptDiscovery = ModuleScriptDiscovery,
    Test = Test,

    --Functions.
    FormatLines = FormatLines,
    RunModuleScript = RunModuleScript,
    RunTests = RunTests,
}