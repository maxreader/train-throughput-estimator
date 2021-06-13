local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local tte_gui = require("script.tte_gui")
local calculate_train_data = require("script.simulation")
local data_functions = require("script.data_functions")

local function log_table(tab)
    game.print(serpent.line(tab, {comment = true, refcomment = true, tablecomment = false}))
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

local function add_train_data(entities)
    local RSD = global.rolling_stock_data
    -- TODO: Two selection modes: only rolling stock selected, vs select entire train of selected
    -- Going with only selected rolling stock
    local unsorted_prototype_count = {}
    local types = {
        ["locomotive"] = {},
        ["cargo-wagon"] = {},
        ["fluid-wagon"] = {},
        ["artillery-wagon"] = {}
    }
    for k, v in pairs(entities) do
        if RSD[v.name] then
            local name = v.name
            table.insert(types[v.type], name)
            local n = unsorted_prototype_count[name] or 0
            unsorted_prototype_count[name] = n + 1
        end
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

gui.hook_events(function(e)
    local msg = gui.read_action(e)
    if msg then if msg.gui == "tte-gui" then tte_gui.handle_action(e, msg) end end
end)

local on_gui_location_changed = function(event)
    local element = event.element
    if element.name == "tte-gui" then
        local player_index = event.player_index
        if not global.player_data[player_index] then
            global.player_data[player_index] = {}
            global.player_data[event.player_index].gui = {position = element.location}
        end
    end
end

event.on_gui_location_changed(on_gui_location_changed)

local function refresh_gui(player, player_data)
    if player_data and player_data.gui then tte_gui.destroy(player_data) end
    tte_gui.build_gui(player, player_data)
end

local function give_tool(player)
    if player.clear_cursor() then
        player.cursor_stack.set_stack {name = "tte-selection-tool", count = 1}
    end
end

event.register("tte-get-selection-tool", function(e)
    local player = game.get_player(e.player_index)
    -- local player_table = global.players[e.player_index]
    give_tool(player)
end)

event.on_player_alt_selected_area(function(e)
    if e.item == "tte-selection-tool" then add_train_data(e.entities) end
end)

event.on_player_selected_area(function(e)
    if e.item == "tte-selection-tool" then
        if add_train_data(e.entities) then
            local i = e.player_index
            local player = game.get_player(i)
            local player_data = global.players[i]
            tte_gui.refresh_consists(player_data)
            tte_gui.open(player, player_data)
        end
    end
end)

local function init_player(i)
    local player = game.get_player(i)
    global.players[i] = {}
    refresh_gui(player, global.players[i])

end

event.on_player_created(function(e) init_player(e.player_index) end)

event.on_player_removed(function(e) global.players[e.player_index] = nil end)

event.on_nth_tick(7, function(e)
    local player_to_update = next(global.players_to_update, nil)
    if player_to_update then tte_gui.update(global.players[player_to_update]) end
end)

event.on_configuration_changed(function(e)
    -- Generate table of relevant data for each rolling stock
    -- TODO: add check to only recalc if things have actually changed
    data_functions.generate_rolling_stock_data()
    data_functions.generate_fuel_data()
    -- Recalculate cache of train throughput data
    data_functions.regenerate_train_data()
    -- TODO: add purge of unused sim data
    for i, player in pairs(game.players) do
        local player_table = global.players[i]
        refresh_gui(player, player_table)
    end
end)

event.on_init(function()
    data_functions.generate_rolling_stock_data()
    data_functions.generate_fuel_data()
    global.train_data = {}
    global.players = {}
    global.sim_data = {}
    global.players_to_update = {}
    global.consist_ids = {}
    for i, player in pairs(game.players) do init_player(i) end
end)

local function clear_cache()
    data_functions.generate_rolling_stock_data()
    data_functions.generate_fuel_data()
    data_functions.regenerate_train_data()
end

commands.add_command("clearTTECache", "", clear_cache)

-- TODO: add shortcut
--[[event.on_lua_shortcut(function(e)
  if e.prototype_name == "rcalc-get-selection-tool" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    give_tool(player, player_table, player_table.last_tool_measure)
  end
end)]]
