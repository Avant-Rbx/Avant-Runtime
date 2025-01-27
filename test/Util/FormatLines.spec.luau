--Tests FormatLines.
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FormatLines = require(ReplicatedStorage.AvantRuntime.Util.FormatLines)

return function()
    describe("The ModuleSandbox function", function()
        it("should format single string.", function()
            local Lines = FormatLines({"Test string"}, 1)
            expect(#Lines).to.equal(1)
            expect(Lines[1]).to.equal("Test string")
        end)

        it("should format multiple strings.", function()
            local Lines = FormatLines({"Test string 1", "Test string 2"}, 2)
            expect(#Lines).to.equal(1)
            expect(Lines[1]).to.equal("Test string 1 Test string 2")
        end)

        it("should format newlines.", function()
            local Lines = FormatLines({"Test string \n1", "Test string \n2"}, 2)
            expect(#Lines).to.equal(3)
            expect(Lines[1]).to.equal("Test string ")
            expect(Lines[2]).to.equal("1 Test string ")
            expect(Lines[3]).to.equal("2")
        end)

        it("should format nil.", function()
            local Lines = FormatLines({nil}, 1)
            expect(#Lines).to.equal(1)
            expect(Lines[1]).to.equal("nil")
        end)

        it("should format missing values.", function()
            local Lines = FormatLines({"Test string 1", nil :: any, "Test string \n2", 3 :: any}, 4)
            expect(#Lines).to.equal(2)
            expect(Lines[1]).to.equal("Test string 1 nil Test string ")
            expect(Lines[2]).to.equal("2 3")
        end)
    end)
end