local gui = require("__flib__.gui-beta")

local tte_gui = {}

function tte_gui.build_gui(player)
    gui.build(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            ref = {"window"},
            actions = {on_closed = {gui = "tte-gui", action = "close"}},
            children = {
                -- titlebar
                {
                    type = "flow",
                    ref = {"titlebar", "flow"},
                    children = {
                        {
                            type = "label",
                            style = "frame_title",
                            caption = {"mod-name.train-throughput-estimator"},
                            ignored_by_interaction = true
                        },
                        {
                            type = "empty-widget",
                            style = "flib_titlebar_drag_handle",
                            ignored_by_interaction = true
                        }, {
                            type = "sprite-button",
                            style = "frame_action_button",
                            sprite = "utility/close_white",
                            hovered_sprite = "utility/close_black",
                            clicked_sprite = "utility/close_black",
                            ref = {"titlebar", "close_button"},
                            actions = {on_click = {gui = "tte-gui", action = "close"}}
                        }
                    }
                }, {
                    type = "frame",
                    children = {
                        type = "table",
                        style = "slot_table",
                        column_count = 10,
                        ref = {"tables", 1}
                    }
                }
            }
        }
    })

end

function tte_gui.destroy(player_table)
    player_table.gui.refs.window.destroy()
    player_table.gui.tte_gui = nil
end

function tte_gui.open(player, player_table)
    local gui_data = player_table.gui
    gui_data.state.visible = true
    gui_data.refs.window.visible = true

    if not gui_data.state.pinned then player.opened = gui_data.refs.window end
end

function tte_gui.handle_action(e, msg)
    local player_index = e.player_index
    local player = game.get_player(player_index)
    local player_data = global.players[player_index]
    local gui_data = player_data.gui
    local refs = gui_data.refs
    local state = gui_data.state

    local action = msg.action

    if action == "open" then
        tte_gui.open(player, player_data)
    elseif action == "close" then
        if not state.pinning then
            -- de-focus the dropdowns if they were focused
            refs.window.focus()

            state.visible = false
            refs.window.visible = false

            if player.opened == refs.window then player.opened = nil end
        end
    end

end

return tte_gui
