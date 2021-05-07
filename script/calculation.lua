local table = require("__flib__.table")
-- TODO: Stop assuming fixed air resistance

local junction_length = 4 -- tiles
local fuel_acceleration_bonus = 2.5 -- for nuc. fuel
local fuel_top_speed_mult = 1.15 -- for nuc. fuel

local function time_to_clear(arg)
    local total_distance = arg.distance
    local weight = arg.weight
    local friction = arg.friction
    local power = arg.power * fuel_acceleration_bonus
    local maxV = arg.maxSpeed * fuel_top_speed_mult

    local air_resistance = 0.0075

    local D = 0
    local V = 0
    local t = 0
    while D < total_distance do
        t = t + 1
        D = D + V
        V = math.max(0, math.abs(V) - friction / weight)
        V = V + power / weight
        V = V * (1 - air_resistance * 1000 / weight)
        if V < friction / weight then break end
        V = math.min(V, maxV)
    end
    t = t + 1
    return t
end

local function calculate_throughput(train_data)
    local t = time_to_clear(train_data)
    local type_counts = train_data.type_counts
    local WPM = (type_counts["cargo-wagon"] + type_counts["fluid-wagon"]) * (3600 / t)
    local CPM = train_data.item_capacity * 3600 / t
    local FPM = train_data.fluid_capacity * 3600 / t
    local maxKMH = train_data.maxSpeed * 60 * 3600 / 1000
    return {WPM = WPM, CPM = CPM, FPM = FPM, maxKMH = maxKMH}
end

local function calculate_train_data(prototype_count)
    local prototype_data = global.rolling_stock_data
    local distance = junction_length
    local weight = 0
    local friction = 0
    local power = 0
    local maxSpeed = math.huge
    local type_counts = {
        ["locomotive"] = 0,
        ["cargo-wagon"] = 0,
        ["fluid-wagon"] = 0,
        ["artillery-wagon"] = 0
    }
    local item_capacity = 0
    local fluid_capacity = 0
    for k, v in pairs(prototype_count) do
        local thisData = prototype_data[k]
        distance = distance + v * 7
        weight = weight + v * thisData.weight
        friction = friction + v * thisData.friction_force
        power = power + v * thisData.power
        maxSpeed = math.min(maxSpeed, thisData.max_speed or maxSpeed)
        item_capacity = item_capacity + v * thisData.item_capacity
        fluid_capacity = fluid_capacity + v * thisData.fluid_capacity
        type_counts[thisData.type] = type_counts[thisData.type] + v
    end
    power = power / 1000
    local train_data = {
        distance = distance,
        weight = weight,
        friction = friction,
        power = power,
        maxSpeed = maxSpeed,
        item_capacity = item_capacity,
        fluid_capacity = fluid_capacity,
        type_counts = type_counts
    }
    local throughput_data = calculate_throughput(train_data)
    train_data = table.deep_merge {train_data, throughput_data}
    return train_data
end

return calculate_train_data
