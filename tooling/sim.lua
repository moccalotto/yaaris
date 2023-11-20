local function d20()
    return math.random(1, 20)
end


local simcount = 100000
local startVal = 11
local sum = 0

for _ = 1, simcount, 1 do
    local val = startVal
    for _ = 1, 10, 1 do
        if d20() > val then
            val = val + 1
        end
    end
    sum = sum + val
end

print(sum / simcount)
