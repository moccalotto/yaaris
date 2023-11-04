-- Sort selected areas of a text file
--
-- Each area has a number of sections,
-- and each section has a headline that
-- is used as a key.
--
-- The program simply treats each section as a string, and treats each area as a
-- collection of strings. The strings are sorted such that the sections in
-- the area will appear in order.
--
-- For now, only asciidoc (and markdown) headlines are supported, but
-- description lists are on the way
--
-- TODO:
-- Variables and substitutions with evaluation via dostring
-- Syntax for settings vars could be
-- {{?  mufassa = "tjams" }}
-- {{? mufassa tjams }}
--
-- Syntax for inserting vars could be
-- {{:: string.upper(mufassa) }}
-- my little pony is {{: mufassa .. " næsehorn "}}
--
-- Can assist in streamlining data across the three guides.
-- Can ease links.
--
-- Maybe a quick var insert:
-- @@@mufassa           (inserts the contents of mufassa variable)
--

local filename = arg[1]

-- Check that a filename was given
if filename == nil then
    io.stderr:write(string.format("usage: %s [filename]", arg[0]))
    os.exit(0)
end

-- Check that file exists
local f = io.open(filename, "r+")
if not f then
    io.stderr:write(string.format("file '%s' does not exist", filename))
    os.exit(1)
end

-- Some variables to help us
local MODE_NONE = 0       -- State machine: scanning for START_SORT commands
local MODE_SORTING = 1    -- State machine: sorting, and looking for END_SORT commands.
local mode = MODE_NONE    -- State machine: current mode
local sortKeyPattern = "" -- If a line matches this pattern, is a section headline (a sort key)
local output = ""         -- Output buffer
local sections = {}       -- The sections we're currently sorting.
local lineno = 0          -- Read the file into an array of lines
for line in f:lines() do
    lineno = lineno + 1

    --
    -- SCANNING
    --
    if mode == MODE_NONE then
        local sortArg = string.match(line, "^//%s*START_SORT%s*([=:]+)")

        if sortArg then -- We've encountered a "start sort" command. So we enter sorting-mode
            if string.sub(sortArg, 1, 1) == "=" then
                sortKeyPattern = "^" .. sortArg .. "%s+"
            elseif sortArg == "::" then
                sortKeyPattern = "%w+::%s*$"
            else
                print("wtf ", sortArg)
                os.exit()
            end
            mode = MODE_SORTING
            sections = {}
        end
        output = output .. "\n" .. line

        --
        -- SORTING
        --
    elseif mode == MODE_SORTING then                      -- We're sorting.
        if nil ~= string.match(line, sortKeyPattern) then -- We found a new section headline/sortkey
            -- Start a new section
            sections[#sections + 1] = line
        elseif nil ~= string.match(line, "^//%s*END_SORT") then -- We should stop sorting
            -- Each section within the current sorting area is a single line
            -- Sort those lines to sort the entire area,
            -- and insert the lines into the output.

            table.sort(sections)
            output = output .. "\n" .. table.concat(sections, "\n")
            output = output .. "\n" .. line -- remember to include the "//END_SORT" in the output
            mode = MODE_NONE
            sections = {}
        else
            -- This happens if we have some (hopefully) blank lines
            -- before the first headline is scanned.
            if sections[#sections] == nil then
                goto continue
            end

            -- This line is a normal line within the section.
            -- Add it to the current section.
            sections[#sections] = sections[#sections] .. "\n" .. line
        end
    else
        error("what!" .. mode)
    end

    ::continue::
end

if not (mode == MODE_NONE and #sections == 0) then
    io.stderr:write("You forgot a closing //END_SORT line!\n")
    print("mode", mode)
    print("sections", #sections)
    os.exit(1)
end

if arg[2] == "--overwrite" then
    f:seek("set")
    f:write(output)
    f:flush()
    f:close()
    os.exit(0)
end

f:close()
print(output)
