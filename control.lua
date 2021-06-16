local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local tte_gui = require("script.tte_gui")
local data_functions = require("script.data_functions")

local function log_table(tab)
    game.print(serpent.line(tab, {comment = true, refcomment = true, tablecomment = false}))
end

gui.hook_events(function(e)
    local msg = gui.read_action(e)
    if msg then if msg.gui == "tte-gui" then tte_gui.handle_action(e, msg) end end
end)

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
    give_tool(player)
end)

event.register("toggle-tte-data-gui", function(e)
    local i = e.player_index
    local player = game.get_player(i)
    local player_data = global.players[i]
    local player_gui = player_data.gui
    if not player_gui then tte_gui.build_gui(player, player_data) end
    tte_gui.toggle(player, player_data)
end)

event.on_lua_shortcut(function(e)
    if e.prototype_name == "tte_shortcut" then
        local player = game.get_player(e.player_index)
        give_tool(player)
    end
end)

local add_train_data = data_functions.add_train_data
event.on_player_alt_selected_area(function(e)
    if e.item == "tte-selection-tool" then
        local selection_mode = settings.get_player_settings(e.player_index)["tte-selection-mode"]
                                   .value
        add_train_data(e.entities, selection_mode)
    end
end)

event.on_player_selected_area(function(e)
    if e.item == "tte-selection-tool" then
        local selection_mode = settings.get_player_settings(e.player_index)["tte-selection-mode"]
                                   .value
        if add_train_data(e.entities, selection_mode) then
            local i = e.player_index
            local player = game.get_player(i)
            local player_data = global.players[i]
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
    data_functions.generate_rolling_stock_data()
    data_functions.generate_fuel_data()
    -- Recalculate cache of train throughput data
    data_functions.regenerate_train_data()
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
