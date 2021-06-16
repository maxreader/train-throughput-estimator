local min = math.min
local max = math.max
local table = require("__flib__.table")
local calculate_train_data = require("script.simulation")

local data_functions = {}

function data_functions.regenerate_train_data()
    local train_data = global.train_data or {}
    local rolling_stock_data = global.rolling_stock_data or {}
    local consist_ids = global.consist_ids or {}
    local sim_data = global.sim_data or {}
    for i, consist_id in pairs(consist_ids) do
        local this_consist_data = train_data[consist_id]
        local prototype_count = this_consist_data.constants.prototype_count
        -- Verify that all constituent rolling stock are still valid
        for prototype, count in pairs(prototype_count) do
            if not rolling_stock_data[prototype] then
                for k, _ in pairs(global.fuel_multipliers) do
                    local sim_id = this_consist_data[k].sim_id
                    local this_sim_data = sim_data[sim_id]
                    local this_sim_data_consist_ids = this_sim_data.consist_ids
                    this_sim_data_consist_ids[consist_id] = nil
                    if not next(this_sim_data_consist_ids) then
                        sim_data[sim_id] = nil
                    end
                end
                train_data[consist_id] = nil
                table.remove(consist_ids, i)
                goto zcontinue
            end
        end
        -- Recalculate data for configurations
        train_data[consist_id] = calculate_train_data(prototype_count, consist_id)
        ::zcontinue::
    end
end

function data_functions.generate_rolling_stock_data()
    global.rolling_stock_data = nil
    local rolling_stock_data = {}
    local rolling_stocks = game.get_filtered_entity_prototypes {{filter = "rolling-stock"}}

    for k, v in pairs(rolling_stocks) do
        rolling_stock_data[k] = {
            name = v.localised_name,
            weight = v.weight or nil,
            friction_force = v.friction_force or nil,
            braking_force = v.braking_force or nil,
            power = v.max_energy_usage,
            max_speed = v.speed or nil,
            air_resistance = v.air_resistance,
            type = v.type,
            item_capacity = ((v.type == "cargo-wagon" and
                v.get_inventory_size(defines.inventory.cargo_wagon)) or
                (v.type == "artillery-wagon" and
                    v.get_inventory_size(defines.inventory.artillery_wagon_ammo))) or 0,
            fluid_capacity = (v.type == "fluid-wagon" and v.fluid_capacity) or 0,
            fuel_slots = v.type == "locomotive" and v.get_inventory_size(defines.inventory.fuel)
        }
    end
    global.rolling_stock_data = rolling_stock_data
end

function data_functions.generate_fuel_data()
    local fuel_multipliers = {}
    local fuel_data = {}
    local fuels = game.get_filtered_item_prototypes({
        -- {filter = "fuel"},
        {filter = "fuel-category", ["fuel-category"] = "chemical", mode = "and"}
    })

    fuel_data["null_fuel"] = {multiplier_id = 0}
    fuel_multipliers[0] = {acceleration = 1, top_speed = 1}
    local i = 2
    for _, fuel in pairs(fuels) do
        local multipliers = {
            acceleration = fuel.fuel_acceleration_multiplier,
            top_speed = fuel.fuel_top_speed_multiplier
        }
        local fuel_value = fuel.fuel_value
        local stack_size = fuel.stack_size
        local fuel_name = fuel.name
        -- Check if set of fuel multipliers is already known
        for k, v in pairs(fuel_multipliers) do
            if table.deep_compare(multipliers, v) then
                fuel_data[fuel_name] = {
                    multiplier_id = k,
                    fuel_value_per_stack = fuel_value * stack_size
                }
                goto continue
            end
        end
        fuel_multipliers[i] = multipliers
        fuel_data[fuel_name] = {multiplier_id = i, fuel_value_per_stack = fuel_value * stack_size}
        i = i + 1
        ::continue::
    end
    global.fuel_multipliers = fuel_multipliers
    global.fuel_data = fuel_data
end

-- Currently unused, probably not ever going to be
function data_functions.get_braking_force_research()
    -- global.braking_force_multipliers
    local braking_force_techs = {}
    local technology_prototypes = game.get_filtered_technology_prototypes {
        {filter = "hidden", invert = true}, {filter = "has-effects", mode = "and"}
    }
    for k, v in pairs(technology_prototypes) do
        local effects = v.effects
        if effects.type == "train-braking-force-bonus" then braking_force_techs[k] = effects end
    end
end

-- Calculate braking distance and saturation throughput
-- Needs to return braking distance and saturation throughput
function data_functions.calculate_bd_and_st(train_constants, speed, braking_force_bonus)
    local weight = train_constants.weight
    local friction = train_constants.friction
    local braking_force = train_constants.braking_force * (1 + braking_force_bonus)
    local ticks_to_stop = speed * weight / (braking_force + friction)
    local braking_distance = max(ticks_to_stop / 2, 1.1) * speed + 2
    local saturation_period = (train_constants.length + braking_distance) / speed
    return {braking_distance = braking_distance, saturation_period = saturation_period}

end

local function consist_sort_function(a, b)
    local train_data = global.train_data
    local a_length = train_data[a].constants.length
    local b_length = train_data[b].constants.length
    if a_length ~= b_length then
        return a_length < b_length
    else
        return a < b
    end
end

local function sort_and_calculate(entities)

    local RSD = global.rolling_stock_data
    local types = {
        ["locomotive"] = {},
        ["cargo-wagon"] = {},
        ["fluid-wagon"] = {},
        ["artillery-wagon"] = {}
    }

    local unsorted_prototype_count = {}
    for k, v in pairs(entities) do
        local name = v.name
        table.insert(types[v.type], name)
        local n = unsorted_prototype_count[name] or 0
        unsorted_prototype_count[name] = n + 1
    end
    if next(unsorted_prototype_count) then
        local sorted_prototype_count = {}
        for _type, names in pairs(types) do
            table.sort(names)
            for _, name in pairs(names) do
                sorted_prototype_count[name] = unsorted_prototype_count[name]
            end
        end
        -- Create consist string to use as ID and display
        local consist_id = ""
        for k, v in pairs(sorted_prototype_count) do
            consist_id = consist_id .. tostring(v) .. "-[item=" .. k .. "] "
        end
        local train_data = global.train_data
        local consist_ids = global.consist_ids
        if not train_data[consist_id] then
            train_data[consist_id] = calculate_train_data(sorted_prototype_count, consist_id)
            consist_ids[#consist_ids + 1] = consist_id
        end
        table.sort(consist_ids, consist_sort_function)
        return true
    end
    return false
end

function data_functions.add_train_data(entities, selection_mode)
    local RSD = global.rolling_stock_data
    -- TODO: Two selection modes: only rolling stock selected, vs select entire train of selected
    -- Going with only selected rolling stock

    -- Either mode needs to produce a list of unsorted prototype counts
    if selection_mode == "Entities" then
        local only_carriages = {}
        local i = 1
        for k, v in pairs(entities) do
            if RSD[v.name] then
                only_carriages[i] = v
                i = i + 1
            end
        end
        return sort_and_calculate(only_carriages)
    elseif selection_mode == "Trains" then
        local LuaTrains = {}
        for k, v in pairs(entities) do
            if RSD[v.name] then
                local train = v.train
                local train_id = train.id
                if not LuaTrains[train_id] then
                    LuaTrains[train_id] = true
                    return sort_and_calculate(train.carriages)
                end
            end
        end
    end
    return false
end

return data_functions
