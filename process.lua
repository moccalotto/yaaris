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
if arg[1] == nil then
    print(string.format("usage: %s [filename]", arg[0]))
    os.exit(0)
end

-- Check that file exists
local f = io.open(filename, "r+")
if not f then
    print(string.format("file '%s' does not exist", filename))
    os.exit(1)
end

local sorted = require("sorter")(f:lines())

if arg[2] == "--overwrite" then
    f:seek("set")
    f:write(sorted)
    f:flush()
    f:close()
    os.exit(0)
end

f:close()

print(sorted)
