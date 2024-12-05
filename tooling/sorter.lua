-- Some variables to help us
local result = ""         -- Output buffer
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
        line = line .. "\n"
        --
        -- SCANNING
        --
        if mode == MODE_SCAN then
            local sortArg = string.match(line, "^//%s*START_SORT%s*(%S*)%s*$")

            if sortArg then -- We've encountered a "start sort" command. So we enter sorting-mode
                if string.sub(sortArg, 1, 1) == "=" then
                    -- We are sorting by section names
                    -- The type of section we're sorting (i.e. its depth) is denoted by the given number equal characters.
                    -- Every time we encounter a section with the corresponding number of equal signs, we consider that a sorting key.
                    sortKeyPattern = "^" .. sortArg .. "%s+"
                elseif sortArg == "//KEY:" then
                    -- We are sorting by custom keys.
                    -- This means that every time we encounter the string "KEY:" we consider the next line a sorting key.
                    sortKeyPattern = "^%s*//KEY:"
                else
                    -- Unknown sorting type.
                    io.stderr:write(string.format("unsupported sort argument: %s", sortArg))
                    os.exit()
                end

                -- We are done scanning for START_SORT commands, so now we can begin sorting the subsequent lines.
                mode = MODE_SORTING
                sections = {}
                preface = ""
            end

            -- Ensure that the outputted section contains the sort command.
            result = result .. line

            goto continue
        end

        --
        -- SORTING
        --
        if mode == MODE_SORTING then                   -- We're sorting.
            if string.match(line, sortKeyPattern) then -- We found a new section headline/sortkey
                -- Start a new section
                sections[#sections + 1] = line
                goto continue
            end

            if string.match(line, "^//%s*END_SORT") then
                -- We have encountered a command to stop sorting. So we should stop sorting.
                -- Each section within the current sorting area is a single string
                -- Sort those strings to sort the entire area,
                -- and compile/combine/join the strings into the output.

                table.sort(sections)
                local sorted = table.concat(sections, "")

                -- Compile the resulting sorted text.
                result = result .. preface .. sorted .. line

                -- Reset the state machine to start looking for new areas to sort.
                mode = MODE_SCAN
                sections = {}
                preface = ""
                goto continue
            end

            -- This happens if we have preface text before the first heading/sortkey
            -- Preface text is paragraph text that comes after START_SORT, but before the
            -- first sorting key/section is encountered.
            if nil == sections[#sections] then
                preface = preface .. line
                goto continue
            end

            -- This line is a normal line within the section.
            -- Add it to the current section.
            sections[#sections] = sections[#sections] .. line
        end

        ::continue::
    end

    if not (mode == MODE_SCAN and #sections == 0) then
        error("you must be missing an END_SORT or similar")
        return nil
    end

    return result
end

return sorter
