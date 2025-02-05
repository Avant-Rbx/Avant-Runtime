# Avant Runtime
Avant Runtime is a library used to run unit tests on Roblox. For the plugin,
see [Avant-Plugin](https://github.com/Avant-Rbx/Avant-Plugin).

This is the successor to [Nexus Unit Testing](https://github.com/TheNexusAvenger/Nexus-Unit-Testing).

⚠️ At the moment, only [TestEZ](https://github.com/Roblox/testez) is supported.
Support of [Jest](https://github.com/Roblox/jest-roblox) is wanted, but isn't
supported due to the difficulty of integration. Help is wanted to properly integrate
Jest. The main problem is creating sub-tests and updating their state at the end
of `describe`, `it`, and others, as well as properly starting tests with the
developer-provied runtime.

## Goals
Avant exists to provide the following:
- Provide a common interface that can be used with multiple test libraries
  (TestEZ, Jest).
- Improve test isolation and re-running by allowing `ModuleScript`s to be
  `require`d multiple times.
- Isolate and store the output of individual tests.

## Writing Tests
For TestEZ, [see TestEZ's docs](https://roblox.github.io/testez/getting-started/writing-tests/).

In order for tests to be detected, the name of the `ModuleScript` must
end with `.spec`.

## Running Tests
*This is not relevant for the plugin.*

Avant provides a simple test runner for quick testing with [`RunTests`](./src/RunTests.luau).
It can be used as a reference for custom runners.

```luau
local RunTests = require(game:GetService("TestService").AvantRuntime.RunTests) --Replace with where the module is.
local Results = RunTests() --Returns a table with the total NOT_RUN, PASSED, FAILED, and SKIPPED tests.
```

## License
Avant Runtime is available under the terms of the MIT License. See
[LICENSE](LICENSE) for details.