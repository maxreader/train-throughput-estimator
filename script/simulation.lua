local format_number = require("util.format").format_number

local min = math.min
local max = math.max

-- TODO: Stop assuming fixed air resistance

-- Make this a mod setting
local maximum_junction_length = 128 -- tiles

local function do_simulation(power, friction, weight, air_resistance, V_cap, length)
    local total_distance = length + maximum_junction_length
    local t = 0
    local D = 0
    local V = 0
    local next_tile = 1
    local times = {}
    local velocities = {}
    while D < total_distance do
        t = t + 1
        D = D + V
        -- Removed abs(V) because we never sim deacceleration
        V = max(0, V - friction / weight)
        V = V + power / weight
        V = V * (1 - air_resistance / weight)
        -- Removed because this is now being checked in the parent function
        -- if V < friction / weight then break end
        V = min(V, V_cap)
        while D > next_tile do
            times[next_tile] = t
            velocities[next_tile] = V
            next_tile = next_tile + 1
        end
    end
    t = t + 1
    -- Add final distance
    --[[global.sim_data[sim_id] = {
        times = times,
        velocities = velocities,
        consist_ids = {[consist_id] = true}
    }]]
    return times, velocities
end

local function calculate_bottleneck_throughput(train_constants, multipliers)
    local weight = train_constants.weight
    local friction = train_constants.friction
    local acceleration_multiplier = multipliers.acceleration
    local power = train_constants.power * acceleration_multiplier
    local length = train_constants.length
    local consist_id = train_constants.consist_id

    local air_resistance = 0.0075 * 1000

    local min_V = power / weight * (1 - air_resistance / weight)
    local V_cap = train_constants.maxSpeed * multipliers.top_speed
    local sim_id = serpent.line({power, friction, weight, air_resistance, V_cap, length})
    local this_sim_data = global.sim_data[sim_id]

    local maxV = this_sim_data and this_sim_data.maxV or 0
    if not this_sim_data then
        local times = {}
        local velocities = {}
        if min_V < friction / weight then
            -- Train is basically never moving, let's not waste time actually calculating this mistake of a config
            maxV = min_V
            for i = 1, (length + maximum_junction_length) do
                times[i] = i / maxV
                velocities[i] = maxV
            end
        else
            local acc = power - friction
            maxV = min(acc / air_resistance - acc / weight, V_cap)
            times, velocities =
                do_simulation(power, friction, weight, air_resistance, V_cap, length)
        end
        global.sim_data[sim_id] = {
            times = times,
            velocities = velocities,
            maxV = maxV,
            consist_ids = {[consist_id] = true}
        }
    else
        this_sim_data.consist_ids[consist_id] = true
    end
    return sim_id, maxV
end

local function calculate_train_data(prototype_count, consist_id)
    local prototype_data = global.rolling_stock_data
    local length = -1
    local weight = 0
    local friction = 0
    local braking_force = 0
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
    local tooltip_string = {"", {"tte-gui.rolling-stock"}, ": "}
    local i = 1
    for k, v in pairs(prototype_count) do
        local thisData = prototype_data[k]
        length = length + v * 7
        weight = weight + v * thisData.weight
        friction = friction + v * thisData.friction_force
        braking_force = braking_force + thisData.braking_force
        power = power + v * thisData.power
        maxSpeed = min(maxSpeed, thisData.max_speed or maxSpeed)
        item_capacity = item_capacity + v * thisData.item_capacity
        fluid_capacity = fluid_capacity + v * thisData.fluid_capacity
        type_counts[thisData.type] = type_counts[thisData.type] + v
        tooltip_string = {"", tooltip_string, "\n\t", thisData.name, ": ", tostring(v)}
    end

    -- Combine all that relevant data into a tooltip
    -- TODO: Maybe add total item stack/fluid count

    power = power / 1000

    local locale_lookup = {
        ["length"] = {(length + 1) / 7, 0},
        ["weight"] = {weight * 1000, false, "N"},
        ["power"] = {power * 60 * 1000, false, "W"},
        ["friction"] = {friction * 60 * 1000, false, "W"},
        ["braking_force"] = {braking_force * 60 * 1000, false, "W"}
    }

    -- TODO: format numbers
    for k, v in pairs(locale_lookup) do
        local number = format_number(v[1], v[2], true)
        tooltip_string = {"", tooltip_string, "\n", {"tte-gui." .. k}, ": ", number, v[3]}
    end

    local train_constants = {
        consist_id = consist_id,
        tooltip_string = tooltip_string,
        prototype_count = prototype_count,
        wagon_count = (type_counts["cargo-wagon"] or 0) + (type_counts["fluid-wagon"] or 0) +
            (type_counts["artillery-wagon"] or 0),
        length = length,
        weight = weight,
        friction = friction,
        braking_force = braking_force,
        power = power,
        maxSpeed = maxSpeed,
        item_capacity = item_capacity,
        fluid_capacity = fluid_capacity,
        type_counts = type_counts
    }
    local train_data = {constants = train_constants}
    for k, multipliers in pairs(global.fuel_multipliers) do
        local sim_id, maxV = calculate_bottleneck_throughput(train_constants, multipliers)
        train_data[k] = {sim_id = sim_id, maxV = maxV}
    end
    return train_data
end

return calculate_train_data
