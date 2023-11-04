-- Some variables to help us
local str = ""            -- Output buffer
local MODE_SCAN = 0       -- State machine: scanning for START_SORT commands
local MODE_SORTING = 1    -- State machine: sorting, and looking for END_SORT commands.
local mode = MODE_SCAN    -- State machine: current mode
local sortKeyPattern = "" -- If a line matches this pattern, is a section headline (a sort key)
local sections = {}       -- The sections we're currently sorting.
local preface = ""        -- contains the text in a chunk that comes before the first section headline

---Scan a file and sort the headings of the chunks marked for sorting
---@param lines any iterator
---@return string|nil  The sorted string. Nil if error
local function sorter(lines)
    for line in lines do
        --
        -- SCANNING
        --
        if mode == MODE_SCAN then
            local sortArg = string.match(line, "^//%s*START_SORT%s*(%S*)%s*$")

            if sortArg then -- We've encountered a "start sort" command. So we enter sorting-mode
                if string.sub(sortArg, 1, 1) == "=" then
                    sortKeyPattern = "^" .. sortArg .. "%s+"
                elseif sortArg == "::" then
                    sortKeyPattern = "::%s*$"
                elseif sortArg == "[[]]" then
                    sortKeyPattern = "^%[%[[%w_]+%]%]"
                else
                    io.stderr:write(string.format("unsupported sort argument: %s", sortArg))
                    os.exit()
                end

                mode = MODE_SORTING
                sections = {}
                preface = ""
            end

            str = str .. "\n" .. line

            goto continue
        end

        --
        -- SORTING
        --
        if mode == MODE_SORTING then                          -- We're sorting.
            if nil ~= string.match(line, sortKeyPattern) then -- We found a new section headline/sortkey
                -- Start a new section
                sections[#sections + 1] = line
                goto continue
            end

            if nil ~= string.match(line, "^//%s*END_SORT") then -- We should stop sorting
                -- Each section within the current sorting area is a single line
                -- Sort those lines to sort the entire area,
                -- and insert the lines into the output.

                table.sort(sections)
                sorted = table.concat(sections, "\n")

                -- is there a preface?
                if #preface > 0 then
                    -- yes, so add preface text to beginning of sorted chunk
                    str = str .. "\n" .. preface
                end
                str = str .. "\n" .. sorted -- add the sorted sections
                str = str .. "\n" .. line   -- add "//END_SORT" line
                mode = MODE_SCAN
                sections = {}
                preface = ""
                goto continue
            end

            -- This happens if we have preface text before the first heading/sortkey
            if nil == sections[#sections] then
                preface = preface .. "\n" .. line
                goto continue
            end

            -- This line is a normal line within the section.
            -- Add it to the current section.
            sections[#sections] = sections[#sections] .. "\n" .. line
        end

        ::continue::
    end

    if not (mode == MODE_SCAN and #sections == 0) then
        error("you must be missing an END_SORT or similar")
        return nil
    end

    return str
end

return sorter
