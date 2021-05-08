local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local tte_gui = require("script.tte_gui")
local calculate_train_data = require("script.calculation")

local function log_table(tab)
    game.print(serpent.block(tab, {comment = true, refcomment = true, tablecomment = false}))
end

local function regenerate_train_data()
    local train_data = global.train_data
    local rolling_stock_data = global.rolling_stock_data
    for prototype_count, _ in pairs(train_data) do
        -- Verify that all constituent rolling stock are still valid
        for prototype, count in pairs(prototype_count) do
            if not rolling_stock_data[prototype] then
                train_data[prototype_count] = nil
                goto zcontinue
            end
        end
        -- Recalculate data for configurations
        train_data[prototype_count] = calculate_train_data(prototype_count)
        ::zcontinue::
    end
end

local function give_tool(player)
    if player.clear_cursor() then
        player.cursor_stack.set_stack {name = "tte-selection-tool", count = 1}
    end
end

local function generate_rolling_stock_data()
    global.rolling_stock_data = nil
    local rolling_stock_data = {}
    local rolling_stocks = game.get_filtered_entity_prototypes {{filter = "rolling-stock"}}
    for k, v in pairs(rolling_stocks) do
        rolling_stock_data[k] = {
            weight = v.weight or nil,
            friction_force = v.friction_force or nil,
            braking_force = v.braking_force or nil,
            power = v.max_energy_usage,
            max_speed = v.speed or nil,
            type = v.type,
            item_capacity = (v.type == "cargo-wagon" and
                v.get_inventory_size(defines.inventory.cargo_wagon)) or 0,
            fluid_capacity = (v.type == "fluid-wagon" and v.fluid_capacity) or 0
        }
    end
    global.rolling_stock_data = rolling_stock_data
end

local function add_train_data(entities)
    local RSD = global.rolling_stock_data
    if not RSD then generate_rolling_stock_data() end
    -- Two selection modes: only rolling stock selected, vs select entire train of selected
    -- Going with only selected rolling stock
    local prototype_count = {}
    for k, v in pairs(entities) do
        local name = v.name
        local n = prototype_count[name] or 0
        if RSD[v.type] then prototype_count[name] = n + 1 end
    end

    if not global.train_data then global.train_data = {} end
    local train_data = global.train_data
    if not train_data[prototype_count] then
        train_data[prototype_count] = calculate_train_data(prototype_count)
    end
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
    if player_data and player_data.gui then
        tte_gui.destroy(player_data)
    else
        player_data = {gui = {}}
    end
    tte_gui.build_gui(player, player_data)
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
        add_train_data(e.entities)
        local i = e.player_index
        local player = game.get_player(i)
        local player_data = global.players[i]
        tte_gui.build_gui(player, player_data)
        tte_gui.open(player, player_data)
        tte_gui.update(player_data)
        --[[for k, v in pairs(global.train_data) do
            log_table(k)
            log_table(v.WPM)
        end]]
    end
end)

event.on_configuration_changed(function(e)
    -- Generate table of relevant data for each rolling stock
    generate_rolling_stock_data()
    -- Recalculate cache of train throughput data
    regenerate_train_data()
    for i, player in pairs(game.players) do
        local player_table = global.players[i]
        refresh_gui(player, player_table)
    end
end)

event.on_init(function()
    generate_rolling_stock_data()
    global.train_data = {}
    global.players = {}
    for i, player in pairs(game.players) do
        global.players[i] = {}
        refresh_gui(player, global.players[i])
    end
end)

local function clear_cache()
    generate_rolling_stock_data()
    global.train_data = {}
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
