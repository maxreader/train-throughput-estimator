local gui = require("__flib__.gui-beta")

local tte_gui = {}

function tte_gui.build_gui(player, player_data)
    local rows = 10
    local refs = gui.build(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            visible = false,
            ref = {"window"},
            actions = {on_closed = {gui = "tte-gui", action = "close"}},
            children = {
                -- titlebar
                {
                    type = "flow",
                    ref = {"titlebar_flow"},
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
                    style = "inside_shallow_frame",
                    direction = "vertical",
                    children = {
                        {
                            type = "frame",
                            style = "tte_toolbar_frame",
                            children = {
                                {type = "empty-widget", style = "flib_horizontal_pusher"},
                                {
                                    type = "label",
                                    style = "caption_label",
                                    caption = {"tte-gui.time-interval"}
                                }, {
                                    type = "drop-down",
                                    ref = {"time_interval_dropdown"},
                                    actions = {
                                        on_selection_state_changed = {
                                            gui = "tte",
                                            action = "update_time_interval"
                                        }
                                    }
                                }
                            }
                        }, {
                            type = "flow",
                            style_mods = {padding = 12, margin = 0},
                            children = {
                                {
                                    type = "frame",
                                    style = "tte_rates_list_box_frame",
                                    direction = "vertical",
                                    children = {
                                        type = "frame",
                                        style = "tte_toolbar_frame",
                                        style_mods = {right_padding = 20},
                                        children = {
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                style_mods = {
                                                    width = 32,
                                                    caption = {"tte-gui.train-config"}
                                                }
                                            },
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                caption = {"tte-gui.wpm"}
                                            },
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                caption = {"tte-gui.ispm"}
                                            },
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                caption = {"tte-gui.fpm"}
                                            },
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                caption = {"tte-gui.max-speed"}
                                            },
                                            {
                                                type = "label",
                                                style = "tte_column_label",
                                                caption = {"tte-gui.braking-distance"}
                                            }
                                        },
                                        {
                                            type = "scroll-pane",
                                            style = "tte_rates_list_box_scroll_pane",
                                            style_mods = {height = rows * 45},
                                            horizontal_scroll_policy = "never",
                                            ref = {"scroll_pane"}
                                        },
                                        {
                                            type = "frame",
                                            style = "tte_data_frame",
                                            ref = {"data_frame"},
                                            children = {{type = "label", style = "caption_label"}}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    })
    refs.titlebar_flow.drag_target = refs.window
    -- refs.window.force_auto_center()
    player_data.gui = {refs = refs, state = {pinned = false, pinning = false, visible = false}}
end

local widths = {120, 60, 60, 60, 60}

function tte_gui.update(player_data)
    local refs = player_data.gui.refs
    local scroll_pane = refs.scroll_pane
    local children = scroll_pane.children

    local i = 0
    for consist, data in pairs(global.train_data) do
        i = i + 1
        local frame = children[i]
        if not frame then
            gui.build(scroll_pane, {
                {
                    type = "frame",
                    style = "tte_rates_list_box_row_frame",
                    children = {
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[1]}
                        },
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[2]}
                        },
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[3]}
                        },
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[4]}
                        },
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[5]}
                        },
                        {
                            type = "label",
                            style = "tte_amount_label",
                            style_mods = {width = widths[1]}
                        }
                    }
                }

            })
            frame = scroll_pane.children[i]
        end

        local consist_string = ""
        for k, v in pairs(consist) do
            consist_string = consist_string .. tostring(v) .. "-[item=" .. k .. "]"
        end

        gui.update(frame, ({
            children = {
                {elem_mods = {caption = consist_string}}, {elem_mods = {caption = data.WPM}},
                {elem_mods = {caption = data.ISPM}}, {elem_mods = {caption = data.FPM}},
                {elem_mods = {caption = data.maxKMH}}, {elem_mods = {caption = ""}}
            }
        }))
    end
    for j = i + 1, #children do children[j].destroy() end
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
