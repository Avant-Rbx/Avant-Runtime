--Runs a test with TestEZ.
--!strict

local Test = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("Test"):WaitForChild("Test"))
local TestRunContext = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("Test"):WaitForChild("TestRunContext"))
local ModuleSandbox = require(script.Parent.Parent:WaitForChild("State"):WaitForChild("ModuleSandbox"))
local TestEZ = require(script.Parent.Parent:WaitForChild("TestEZ"))

local RunTestEZTest = nil
RunTestEZTest = function(TestInstance: Test.Test, RunTest: (...any) -> (), TestNode: any, Sandbox: ModuleSandbox.ModuleSandbox, ...: any): ()
    --Prepare the run context.
    local CurrentTestRunContext = TestRunContext.new(TestInstance)
    CurrentTestRunContext:PrepareChildTests()

    --[[
    Adds a child TestEZ node.
    --]]
    local function AddChildNode(Phrase: string, Callback: (...any) -> (), NodeType: string, NodeModifier: string): (any, Test.Test)
        --Get the test.
        local NewTest = CurrentTestRunContext:GetTest(Phrase)
        if NodeModifier == TestEZ.TestEnum.NodeModifier.Skip then
            NewTest.State = "SKIPPED"
        end

        --Create the child node.
        local NewNode = TestNode:addChild(Phrase, NodeType, NodeModifier)
        NewNode.callback = function(...)
            --Run the test.
            RunTestEZTest(NewTest, Callback, NewNode, ModuleSandbox.new(Sandbox), ...)

            --Update the state.
            if NewNode.modifier == TestEZ.TestEnum.NodeModifier.Skip and NewTest.State ~= "SKIPPED" then
                NewTest.State = "SKIPPED"
            end
        end

        --Expand and return the node.
        if NodeType == TestEZ.TestEnum.NodeType.Describe then
            NewNode:expand()
        end
        return NewNode, NewTest
    end

    --Prepare the environment.
    local Environment = {}
    Environment["RunTestFunctionHash"] = tostring(RunTest)
    Environment["AddTestOutput"] = function(MessageType: Enum.MessageType, ...)
        TestInstance:AddOutput(MessageType, ...)
    end
    Environment["print"] = function(...)
        TestInstance:AddOutputForCall(Enum.MessageType.MessageOutput, ...)
    end
    Environment["warn"] = function(...)
        TestInstance:AddOutputForCall(Enum.MessageType.MessageWarning, ...)
    end
    setmetatable(Environment, {__index = Sandbox.EnvironmentOverrides})
    setfenv(RunTest, Environment :: any)

    --Prepare the TestEZ globals.
    for Name, Value in TestNode.environment do
        Environment[Name] = Value
    end

    function Environment.describe(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.Describe, TestEZ.TestEnum.NodeModifier.None)
    end
    function Environment.describeFOCUS(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.Describe, TestEZ.TestEnum.NodeModifier.Focus)
    end
    function Environment.describeSKIP(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.Describe, TestEZ.TestEnum.NodeModifier.Skip)
    end
	Environment.fdescribe = Environment.describeFOCUS
	Environment.xdescribe = Environment.describeSKIP

    function Environment.it(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.It, TestEZ.TestEnum.NodeModifier.None)
    end
    function Environment.itSKIP(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.It, TestEZ.TestEnum.NodeModifier.Skip)
    end
    function Environment.itFOCUS(phrase: string, callback: (...any) -> ())
        AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.It, TestEZ.TestEnum.NodeModifier.Focus)
    end
    function Environment.itFIXME(phrase: string, callback: (...any) -> ())
        local ChildNode, ChildTest = AddChildNode(phrase, callback, TestEZ.TestEnum.NodeType.It, TestEZ.TestEnum.NodeModifier.Skip)
        ChildTest:AddOutput(Enum.MessageType.MessageWarning, `FIXME: broken test {ChildNode:getFullName()}`)
    end

	Environment.fit = Environment.itFOCUS
	Environment.xit = Environment.itSKIP

    for _, HookName in {"beforeAll", "afterAll", "beforeEach", "afterEach"} do
        Environment[HookName] = function(Callback: (...any) -> ())
            TestNode.environment[HookName](function(...)
                local Arguments = table.pack(...)
                local ErrorMessageToRethrow = nil
                xpcall(function()
                    Callback(table.unpack(Arguments))
                end, function(ErrorMessage: string)
                    TestInstance:AddOutput(Enum.MessageType.MessageError, ErrorMessage)
                    TestInstance:AddOutput(Enum.MessageType.MessageInfo, debug.traceback(nil, 2))
                    TestInstance.State = "FAILED"
                    ErrorMessageToRethrow = ErrorMessage
                end)
                if ErrorMessageToRethrow then
                    error(ErrorMessageToRethrow)
                end
            end)
        end
    end

    --Run the test.
    local Arguments = table.pack(...)
    TestInstance.State = "INPROGRESS"
    xpcall(function()
        RunTest(table.unpack(Arguments))
        if TestInstance.State == "INPROGRESS" then
            TestInstance.State = "PASSED"
        end
    end, function(ErrorMessage: string)
        TestInstance:AddOutput(Enum.MessageType.MessageError, ErrorMessage)
        TestInstance:AddOutput(Enum.MessageType.MessageInfo, debug.traceback(nil, 2))
        TestInstance.State = "FAILED"
    end)

    --Clear the unused tests.
    CurrentTestRunContext:ClearUnusedChildTests()
end

return function(TestInstance: Test.Test, RunTest: () -> (), Sandbox: ModuleSandbox.ModuleSandbox): ()
    local TestPlan = TestEZ.TestPlan.new()
    local TestNode = TestPlan:addChild(TestInstance.Name, TestEZ.TestEnum.NodeType.Describe)
    TestNode.callback = function(...)
        RunTestEZTest(TestInstance, RunTest, TestNode, Sandbox, ...)
    end
    TestNode:expand()
    TestEZ.TestRunner.runPlan(TestPlan)
end