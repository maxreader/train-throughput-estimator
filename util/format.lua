local format = {}

local max = math.max
function format.round_number(num, precision)
    precision = max(precision or 0, 0)
    return string.format("%." .. (precision) .. "f", num)
end

local prefixes = {
    "k",
    "M",
    "G",
    "T",
    "P",
    "E",
    "Z",
    "Y",
    [0] = "",
    [-1] = "m",
    [-2] = "u",
    [-3] = "n"
}

local log10 = math.log10
local floor = math.floor
local round_number = format.round_number

function format.format_number(num, precision, space)
    local magnitude = log10(num)
    local prefix_index = floor(magnitude / 3)
    if not precision then precision = 1 end

    space = (space and " ") or ""

    num = num / (1000 ^ prefix_index)
    return {"", round_number(num, precision), space, prefixes[prefix_index]}
end

return format

