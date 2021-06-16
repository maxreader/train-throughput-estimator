local gui = require("__flib__.gui-beta")
local table = require("__flib__.table")
local data_functions = require("script.data_functions")
local calculate_bd_and_st = data_functions.calculate_bd_and_st
local format = require("util.format")
local format_number = format.format_number

local tte_gui = {}

local time_intervals = {
    {multiplier = 60, localised_name = {"tte-gui.per_second"}, name = "per_second"},
    {multiplier = 3600, localised_name = {"tte-gui.per_minute"}, name = "per_minute"},
    {multiplier = 21600, localised_name = {"tte-gui.per_hour"}, name = "per_hour"}
}

local function convert_period_to_throughput(train_constants, period, time_interval_index)
    period = period / time_interval_index
    return {
        wagons = train_constants.wagon_count / period,
        fluid = train_constants.fluid_capacity / period,
        item_stacks = train_constants.item_capacity / period
    }
end

local columns

local arrows = {
    type = "flow",
    direction = "vertical",
    style_mods = {width = 24},
    children = {
        {
            type = "sprite-button",
            style = "tte_arrow_button_style",
            sprite = "tte-up-arrow",
            hovered_sprite = "tte-up-arrow-hover",
            actions = {on_click = {gui = "tte-gui", action = "move_consist_up"}}
        }, {
            type = "sprite-button",
            style = "tte_arrow_button_style",
            sprite = "tte-down-arrow",
            hovered_sprite = "tte-down-arrow-hover",
            actions = {on_click = {gui = "tte-gui", action = "move_consist_down"}}
        }
    }
}

local trash_button = {
    type = "sprite-button",
    style = "frame_action_button",
    sprite = 'utility/trash_white',
    actions = {on_click = {gui = "tte-gui", action = "remove_consist_from_rates"}}
}

local function column_label(caption, width, align, tooltip)
    return {
        type = "label",
        style = "tte_column_label",
        caption = caption,
        tooltip = tooltip,
        style_mods = {width = width or nil, horizontal_align = align or "center"}
    }
end

columns = {
    {caption = {""}, width = 24, button = arrows}, {
        caption = {"tte-gui.train-consist"},
        width = 128,
        align = "left",
        tooltip = {"tte-gui.train-consist-tooltip"}
    }, {caption = {"tte-gui.max-speed"}, width = 70, tooltip = {"tte-gui.max-speed-tooltip"}}, {
        caption = {"tte-gui.braking-distance"},
        width = 105,
        tooltip = {"tte-gui.braking-distance-tooltip"}
    },
    {
        caption = {"tte-gui.sat-throughput"},
        width = 130,
        tooltip = {"tte-gui.sat-throughput-tooltip"}
    }, {caption = {"tte-gui.wpm"}, width = 60, tooltip = {"tte-gui.wpm-tooltip"}},
    {caption = {"tte-gui.ispm"}, width = 80, tooltip = {"tte-gui.ispm-tooltip"}},
    {caption = {"tte-gui.fpm"}, width = 80, tooltip = {"tte-gui.fpm-tooltip"}},
    {
        caption = {"tte-gui.refuel-interval"},
        width = 105,
        tooltip = {"tte-gui.refuel-interval-tooltip"}
    }, {caption = {""}, width = 24, button = trash_button}
}

local column_labels = table.map(columns, function(v)
    return column_label(v.caption, v.width, v.align, v.tooltip)
end)
local empty_row_frame_children = table.map(columns, function(v)
    if v.button then
        return v.button
    else
        return {
            type = "label",
            style = "tte_amount_label",
            style_mods = {width = v.width, horizontal_align = v.align}
        }
    end
end)
local empty_row_frame = {
    type = "frame",
    style = "tte_rates_list_box_row_frame",
    style_mods = {top_padding = 4},
    children = empty_row_frame_children
}

function tte_gui.build_gui(player, player_data)
    if not player_data.gui then player_data.gui = {} end
    local rows = 10
    local braking_force_bonus = player.force.train_braking_force_bonus * 100

    local titlebar_flow = {
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
    }

    local toolbar_frame = {
        type = "frame",
        style = "tte_toolbar_frame",
        children = {
            {type = "empty-widget", style = "flib_horizontal_pusher"}, {
                type = "label",
                style = "caption_label",
                caption = {"tte-gui.directionality"},
                tooltip = {"tte-gui.directionality-tooltip"}
            }, {
                type = "drop-down",
                ref = {"directionality_dropdown"},
                actions = {
                    on_selection_state_changed = {gui = "tte-gui", action = "update_directionality"}
                },
                items = {{"tte-gui.monodirectional"}, {"tte-gui.bidirectional"}},
                selected_index = 1
            }, {type = "empty-widget", style = "tte_horizontal_spacer"},
            {type = "label", style = "caption_label", caption = {"tte-gui.braking-force-bonus"}}, {
                type = "textfield",
                style = "tte_junction_size_textfield",
                style_mods = {width = 80},
                numeric = true,
                -- allow_decimal = true,
                allow_negative = false,
                clear_and_focus_on_right_click = true,
                lose_focus_on_confirm = true,
                text = tostring(braking_force_bonus),
                ref = {"braking_force_bonus_textfield"},
                actions = {
                    on_text_changed = {
                        gui = "tte-gui",
                        action = "update_braking_force_bonus_textfield"
                    }
                }
            }, {type = "empty-widget", style = "tte_horizontal_spacer"},
            {type = "label", style = "caption_label", caption = {"tte-gui.fuel-label"}}, {
                type = "choose-elem-button",
                style = "tte_fuel_choose_elem_button",
                style_mods = {right_margin = -8},
                elem_type = "item",
                elem_filters = {
                    {filter = "fuel"},
                    {filter = "fuel-category", ["fuel-category"] = "chemical", mode = "and"}
                },
                ref = {"fuel_button"},
                actions = {on_elem_changed = {gui = "tte-gui", action = "update_fuel_button"}}
            }, {type = "empty-widget", style = "tte_horizontal_spacer"},
            {type = "label", style = "caption_label", caption = {"tte-gui.time-interval"}}, {
                type = "drop-down",
                ref = {"time_interval_dropdown"},
                actions = {
                    on_selection_state_changed = {gui = "tte-gui", action = "update_time_interval"}
                },
                items = table.map(time_intervals, function(v) return v.localised_name end),
                selected_index = 2
            }
        }
    }

    local junction_size_frame = {
        type = "frame",
        style = "tte_junction_size_frame",
        ref = {"junction_size_frame"},
        children = {
            {
                type = "label",
                style = "subheader_caption_label",
                caption = {"tte-gui.junction-size-select-label"}
            }, {
                type = "slider",
                style = "tte_junction_size_slider",
                minimum_value = 1,
                -- TODO: Connect to mod setting
                maximum_value = 128,
                slider_value = 32,
                value_step = 1,
                ref = {"junction_size_slider"},
                actions = {
                    on_value_changed = {gui = "tte-gui", action = "update_junction_size_slider"}
                }
            }, {
                type = "textfield",
                style = "tte_junction_size_textfield",
                numeric = true,
                -- allow_decimal = true,
                allow_negative = false,
                clear_and_focus_on_right_click = true,
                lose_focus_on_confirm = true,
                text = "32",
                ref = {"junction_size_textfield"},
                actions = {
                    on_text_changed = {gui = "tte-gui", action = "update_junction_size_textfield"}
                }
            }
        }
    }

    local refs = gui.build(player.gui.screen, {
        {
            type = "frame",
            direction = "vertical",
            visible = false,
            ref = {"window"},
            actions = {on_closed = {gui = "tte-gui", action = "close"}},
            children = {
                -- titlebar
                titlebar_flow, {
                    type = "frame",
                    style = "inside_shallow_frame",
                    direction = "vertical",
                    children = {
                        toolbar_frame, {
                            -- horizontal flow
                            type = "flow",
                            style_mods = {padding = 12, margin = 0},
                            children = {
                                {
                                    type = "flow",
                                    direction = "vertical",
                                    style_mods = {right_margin = 8},
                                    children = {
                                        {
                                            type = "frame",
                                            style = "tte_rates_list_box_frame",
                                            direction = "vertical",
                                            style_mods = {minimal_width = 128, bottom_margin = 8},
                                            children = {
                                                {
                                                    type = "frame",
                                                    style = "tte_toolbar_frame",
                                                    style_mods = {
                                                        right_padding = 20,
                                                        horizontally_stretchable = true,
                                                        horizontal_align = "center"
                                                    },
                                                    children = {
                                                        {
                                                            type = "label",
                                                            style = "tte_column_label",
                                                            caption = {"tte-gui.train-consist"},
                                                            style_mods = {
                                                                width = 128,
                                                                horizontal_align = "center"
                                                            }
                                                        }
                                                    }
                                                }, {
                                                    type = "scroll-pane",
                                                    style = "tte_consist_list_box_scroll_pane",
                                                    style_mods = {height = (rows --[[- 3)]] ) * 45},
                                                    horizontal_scroll_policy = "never",
                                                    ref = {"consist_scroll_pane"}
                                                }
                                            }
                                        } --[[
                                        {
                                            type = "frame",
                                            style_mods = {
                                                horizontally_stretchable = true,
                                                vertically_stretchable = true
                                            }
                                        }]]
                                    }
                                }, {
                                    type = "frame",
                                    style = "tte_rates_list_box_frame",
                                    direction = "vertical",
                                    children = {
                                        {
                                            type = "frame",
                                            style = "tte_toolbar_frame",
                                            style_mods = {right_padding = 20},
                                            children = column_labels
                                        }, {
                                            type = "scroll-pane",
                                            style = "tte_rates_list_box_scroll_pane",
                                            style_mods = {height = rows * 45},
                                            horizontal_scroll_policy = "never",
                                            ref = {"data_scroll_pane"}
                                        }, junction_size_frame
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
    -- Make this a setting option
    refs.window.force_auto_center()
    player_data.gui = {
        refs = refs,
        state = {
            pinned = false,
            pinning = false,
            visible = false,
            selected_fuel = "null_fuel",
            time_interval_index = 2,
            selected_junction_size = 32,
            update_junction_size = false,
            braking_force_bonus = braking_force_bonus,
            selected_consists = {},
            inverted_selected_consists = {},
            directionality = 1
        }
    }
end

function tte_gui.refresh_consists(player_data)
    local refs = player_data.gui.refs
    local train_data = global.train_data
    local consist_ids = global.consist_ids

    -- Redo them all, easier than trying to insert into a particular spot
    do
        local consist_scroll_pane = refs.consist_scroll_pane
        local children = consist_scroll_pane.children
        for i, consist_string in pairs(consist_ids) do
            local consist_data = train_data[consist_string]
            local consist_constants = consist_data.constants
            local tooltip = consist_constants.tooltip_string

            local button = children[i]
            if not button then
                button = gui.build(consist_scroll_pane, {
                    {
                        type = "button",
                        style = "list_box_item",
                        caption = consist_string,
                        tooltip = tooltip,
                        style_mods = {horizontally_stretchable = true},
                        actions = {on_click = {gui = "tte-gui", action = "add_consist_to_rates"}}
                    }
                })
            else
                gui.update(button,
                           {elem_mods = {caption = consist_string, tooltip = consist_string}})
            end
        end
    end
end

local function update_row_frame(frame, data_to_display, tooltip, format)
    local frame_update = {}
    for k, value in pairs(data_to_display) do
        if format and type(value) == "number" then value = format_number(value, 2) end
        if k == 2 then
            frame_update[k] = {elem_mods = {caption = value or "", tooltip = tooltip}}
        else
            frame_update[k] = {elem_mods = {caption = value or ""}}
        end
    end
    gui.update(frame, {children = frame_update})
end

local huge = math.huge
function tte_gui.update(player_data)
    local refs = player_data.gui.refs
    local data_scroll_pane = refs.data_scroll_pane
    local children = data_scroll_pane.children
    local state = player_data.gui.state

    local sim_data = global.sim_data
    local train_data = global.train_data

    if state.update_junction_size then
        state.update_junction_size = false
        local junction_size_slider = refs.junction_size_slider
        local junction_size_textfield = refs.junction_size_textfield
        local new_value = state.selected_junction_size
        gui.update(junction_size_slider, {elem_mods = {slider_value = new_value}})
        gui.update(junction_size_textfield, {elem_mods = {text = tostring(new_value)}})
    end

    -- Get fuel type and grab correct data for that fuel
    local selected_fuel = state.selected_fuel or "null_fuel"
    local selected_fuel_data = global.fuel_data[selected_fuel]
    local multiplier_id = selected_fuel_data.multiplier_id
    local fuel_value_per_stack = selected_fuel_data.fuel_value_per_stack or huge -- J/tick-stacks

    -- Get directionality
    local directionality = state.directionality or 1

    local time_interval_index = state.time_interval_index

    local junction_size = state.selected_junction_size or 32

    local selected_consists = state.selected_consists
    local i = 0
    for _, consist_string in pairs(selected_consists) do
        i = i + 1
        local frame = children[i]
        if not frame then
            gui.build(data_scroll_pane, {empty_row_frame})
            frame = data_scroll_pane.children[i]
        end

        local consist_data = train_data[consist_string]
        local train_constants = consist_data.constants
        local tooltip_string = train_constants.tooltip_string

        -- Get data for this fuel, then by directionality
        local multiplier_data = consist_data[multiplier_id][directionality]
        local this_sim_data = sim_data[multiplier_data.sim_id]

        local tile = junction_size + train_constants.length
        local time = this_sim_data.times[tile]
        local maxV = this_sim_data.maxV * 60 * 3.6 -- convert from tiles/tick to km/h

        local time_multiplier = time_intervals[time_interval_index].multiplier

        local throughput = convert_period_to_throughput(train_constants, time, time_multiplier)

        local braking_force_bonus = state.braking_force_bonus / 100
        local saturation_data = calculate_bd_and_st(train_constants, this_sim_data.maxV,
                                                    braking_force_bonus)
        local saturation_period = saturation_data.saturation_period
        local sat_throughput = convert_period_to_throughput(train_constants, saturation_period,
                                                            time_multiplier)
        -- Time in ticks to refuel, possibly lump .min_fuel_slots/ .power into one table call
        local refuel_interval = train_constants.min_fuel_slots * fuel_value_per_stack /
                                    train_constants.power / 1000 / time_multiplier

        -- Convert to minutes, tostring to avoid getting SI units tacked on in update function
        -- refuel_interval = tostring(refuel_interval)

        local data_to_display = {
            "", consist_string, maxV, saturation_data.braking_distance, sat_throughput.wagons,
            throughput.wagons, throughput.item_stacks, throughput.fluid, refuel_interval, ""
        }
        update_row_frame(frame, data_to_display, tooltip_string, true)

    end
    for j = i + 1, #children do children[j].destroy() end
end

function tte_gui.update_junction_selection(player_data)
    local refs = player_data.gui.refs
    local junction_size_slider = refs.junction_size_slider
    local junction_size_textfield = refs.junction_size_textfield
    local new_value = player_data.gui.state.selected_junction_size
    gui.update(junction_size_slider, {elem_mods = {slider_value = new_value}})
    gui.update(junction_size_textfield, {elem_mods = {text = new_value}})

end

function tte_gui.destroy(player_table)
    player_table.gui.refs.window.destroy()
    player_table.gui = nil
end

function tte_gui.open(player, player_table)
    local gui_data = player_table.gui
    gui_data.state.visible = true
    gui_data.refs.window.visible = true
    tte_gui.refresh_consists(player_table)

    if not gui_data.state.pinned then player.opened = gui_data.refs.window end
end

function tte_gui.close(player, player_table)
    local gui_data = player_table.gui
    local refs = gui_data.refs
    local state = gui_data.state
    if not state.pinning then
        -- de-focus the dropdowns if they were focused
        refs.window.focus()

        state.visible = false
        refs.window.visible = false

        if player.opened == refs.window then player.opened = nil end
    end
end

function tte_gui.toggle(player, player_table)
    local opened = player_table.gui.state.visible
    if opened then
        tte_gui.close(player, player_table)
    else
        tte_gui.open(player, player_table)
    end
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
    elseif action == "update_directionality" then
        local new_directionality = e.element.selected_index
        local current_directionality = state.directionality
        if new_directionality ~= current_directionality then
            state.directionality = new_directionality
            tte_gui.update(player_data)
        end
    elseif action == "update_braking_force_bonus_textfield" then
        -- Braking force changing means that only saturation data changes, but we're not updating elements within a row_frame (yet)
        local textfield = refs.braking_force_bonus_textfield
        local new_value = tonumber(textfield.text)
        if not new_value then
            local default = player.force.train_braking_force_bonus * 100
            state.braking_force_bonus = default
            textfield.text = default
        elseif new_value ~= state.braking_force_bonus then
            state.braking_force_bonus = new_value or player.force.train_braking_force_bonus * 100
            tte_gui.update(player_data)
        end
    elseif action == "update_fuel_button" then
        -- Fuel changes everything but consists
        local this_fuel = e.element.elem_value
        local old_fuel = state.selected_fuel
        if this_fuel ~= old_fuel then
            state.selected_fuel = e.element.elem_value
            tte_gui.update(player_data)
        end
    elseif action == "update_time_interval" then
        local new_interval_index = e.element.selected_index
        local old_interval_index = state.time_interval_index
        if new_interval_index ~= old_interval_index then
            state.time_interval_index = new_interval_index
            tte_gui.update(player_data)
        end
    elseif action == "update_junction_size_slider" then
        local slider = refs.junction_size_slider
        local new_value = slider.slider_value
        if new_value ~= state.junction_size then
            state.selected_junction_size = new_value
            state.update_junction_size = true
            table.insert(global.players_to_update, player_index)
        end
    elseif action == "update_junction_size_textfield" then
        local textfield = refs.junction_size_textfield
        local new_value = tonumber(textfield.text)
        if new_value ~= state.junction_size then
            state.selected_junction_size = new_value
            state.update_junction_size = true
            table.insert(global.players_to_update, player_index)
        end
    elseif action == "add_consist_to_rates" then
        local consist_string = e.element.caption
        local selected_consists = state.selected_consists
        local inverted_selected_consists = state.inverted_selected_consists
        -- Need to check if consist already added
        local index = inverted_selected_consists[consist_string]
        if not index then
            index = #selected_consists + 1
            selected_consists[index] = consist_string
            inverted_selected_consists[consist_string] = index
            tte_gui.update(player_data)
        end
    elseif action == "remove_consist_from_rates" then
        local selected_consists = state.selected_consists
        local inverted_selected_consists = state.inverted_selected_consists

        -- button is child of row_frame, want index of row_frame and the caption of its second child
        local button = e.element
        local row_frame = button.parent
        local consist_string = row_frame.children[2].caption
        local index = row_frame.get_index_in_parent()
        table.remove(selected_consists, index)
        inverted_selected_consists[consist_string] = nil
        tte_gui.update(player_data)
    elseif action == "move_consist_up" or action == "move_consist_down" then
        local selected_consists = state.selected_consists
        local inverted_selected_consists = state.inverted_selected_consists

        -- Need index of row_frame
        -- element is an arrow in a vertical flow inside the row_frame
        -- row_frame_A is the one that was clicked and is moving to the position that B currently occupies
        local row_frame_A = e.element.parent.parent
        local row_frames = row_frame_A.parent.children
        local index_A = row_frame_A.get_index_in_parent()
        local index_B
        if action == "move_consist_up" then
            if index_A == 1 then
                return
            else
                index_B = index_A - 1
            end
        elseif action == "move_consist_down" then
            if index_A == #row_frames then
                return
            else
                index_B = index_A + 1
            end
        end

        local row_frame_B = row_frames[index_B]

        -- Get captions, no need to recalculate the data since it's not stored directly in cache
        local row_frame_A_children = row_frame_A.children
        local captions_A = {}
        for i, child in pairs(row_frame_A_children) do captions_A[i] = child.caption end
        local tooltip_A = row_frame_A_children[2].tooltip

        local row_frame_B_children = row_frame_B.children
        local captions_B = {}
        for i, child in pairs(row_frame_B_children) do captions_B[i] = child.caption end
        local tooltip_B = row_frame_B_children[2].tooltip

        update_row_frame(row_frame_A, captions_B, tooltip_B)
        update_row_frame(row_frame_B, captions_A, tooltip_A)

        -- Swap them in selected tables
        local consist_string_A = selected_consists[index_A]
        local consist_string_B = selected_consists[index_B]

        selected_consists[index_A] = consist_string_B
        selected_consists[index_B] = consist_string_A
        inverted_selected_consists[consist_string_A] = index_B
        inverted_selected_consists[consist_string_B] = index_A
    end

end

return tte_gui
