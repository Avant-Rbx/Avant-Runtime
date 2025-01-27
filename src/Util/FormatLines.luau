--Formats a list of items into individual lines to output.
--This prevents advanced features, like table viewing. FormatLines is not suitable for these use cases.
--!strict

return function(Contents: {any}, TotalEntries: number): {string}
    --Format the contents to string.
    local StringContents = {}
    for i = 1, TotalEntries do
        table.insert(StringContents, tostring(Contents[i]))
    end

    --Split the string into lines.
    return string.split(table.concat(StringContents, " "), "\n")
end