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
--

local function trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

local filename = arg[1]

-- Check that a filename was given
if filename == nil then
    io.stderr:write(string.format("usage: %s [filename]", arg[0]))
    os.exit(0)
end

-- Check that file exists
local f = io.open(filename, "rb")
if not f then
    io.stderr:write(string.format("file '%s' does not exist", filename))
    os.exit(1)
end

-- Some variables to help us
local MODE_NONE = 0    -- State machine: scanning for STARTSORT commands
local MODE_SORTING = 1 -- State machine: sorting, and looking for ENDSORT commands.
local mode = MODE_NONE -- State machine: current mode
local prefix =
""                     -- If a line begins with this prefix, it means that it is a section headline, and therefore a sort key
local output = ""      -- Output buffer
local sections = {}    -- The sections we're currently sorting.
local lineno = 0
-- Read the file into an array of lines
for line in f:lines() do
    lineno = lineno + 1
    if mode == MODE_NONE then
        prefix = string.match(line, "^//%s*STARTSORT%s*([=]+)")

        if prefix then -- We've encountered a "start sort" command. So we enter sorting-mode
            prefix = prefix .. " "
            mode = MODE_SORTING
            sections = {}
        end
        output = output .. "\n" .. line
    elseif mode == MODE_SORTING then                   -- We're sorting.
        if string.sub(line, 1, #prefix) == prefix then -- We encountered a headline (a key)
            -- Start a new section
            sections[#sections + 1] = line
        elseif string.match(line, "^//%s*ENDSORT") then -- We should stop sorting
            -- Each section within the current sorting area is a single line
            -- Sort those lines to sort the entire area,
            -- and insert the lines into the output.

            table.sort(sections)
            output = output .. "\n" .. table.concat(sections, "\n")
            output = output .. "\n" .. line -- remember to include the "//ENDSORT" in the output
            mode = MODE_NONE
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

f:close()

print(output)
