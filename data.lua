local data_util = require("__flib__.data-util")
local styles = data.raw["gui-style"].default

local color = {r = 78, g = 121, b = 212}
local alt_color = {}
for k, v in pairs(color) do alt_color[k] = 255 - v end

local rollingStockTypes = {"locomotive", "cargo-wagon", "fluid-wagon", "artillery-wagon"}

data:extend{
    {type = "custom-input", name = "toggle-tte-data-gui", key_sequence = "ALT + T"},
    {type = "custom-input", name = "tte-get-selection-tool", key_sequence = "CTRL + SHIFT + T"}, {
        type = "selection-tool",
        name = "tte-selection-tool",
        localised_name = {"item-name.tte-selection-tool"},
        icons = {
            {icon = data_util.black_image, icon_size = 1, scale = 64}, {
                icon = "__train-throughput-estimator__/graphics/tte-selection-tool.png",
                icon_size = 32,
                mipmap_count = 2
            }
        },
        selection_mode = {"any-entity"},
        alt_selection_mode = {"any-entity"},
        selection_color = color,
        alt_selection_color = alt_color,
        selection_cursor_box_type = "entity",
        alt_selection_cursor_box_type = "entity",
        stack_size = 1,
        flags = {"hidden", "only-in-cursor", "not-stackable"},
        draw_label_for_cursor_render = true,
        entity_type_filters = rollingStockTypes
    }
}

styles.tte_toolbar_frame = {
    type = "frame_style",
    parent = "subheader_frame",
    left_padding = 8,
    -- right_padding = 8,
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        horizontal_spacing = 12,
        vertical_align = "center"
    }
}
styles.tte_rates_list_box_frame = {type = "frame_style", parent = "deep_frame_in_shallow_frame"}

styles.tte_rates_list_box_row_frame = {
    type = "frame_style",
    parent = "statistics_table_item_frame",
    top_padding = 2,
    bottom_padding = 2,
    height = 45,
    horizontally_stretchable = "on",
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        vertical_align = "center",
        horizontal_spacing = 12
    }
}
styles.tte_data_frame = {
    type = "frame_style",
    parent = "subfooter_frame",
    top_padding = 4,
    left_padding = 12,
    right_padding = 12,
    bottom_padding = 2,
    height = 36
}

local min_column_width = 60

styles.tte_amount_label = {
    type = "label_style",
    horizontal_align = "center",
    minimal_width = min_column_width
}

styles.tte_column_label = {
    type = "label_style",
    parent = "bold_label",
    horizontal_align = "center",
    minimal_width = min_column_width
}

styles.tte_rates_list_box_scroll_pane = {
    type = "scroll_pane_style",
    extra_padding_when_activated = 0,
    padding = 0,
    horizontally_stretchable = "on",
    -- height is defined by a per-player setting
    graphical_set = {shadow = default_inner_shadow},
    background_graphical_set = {
        position = {282, 17},
        corner_size = 8,
        overall_tiling_horizontal_padding = 6,
        overall_tiling_vertical_padding = 6,
        overall_tiling_vertical_size = (45 - 12),
        overall_tiling_vertical_spacing = 12
    },
    vertical_flow_style = {type = "vertical_flow_style", vertical_spacing = 0}
}

-- TODO:
--[[
  tool.selection_color = data.color
  tool.selection_cursor_box_type = data.selection_box
  local alt_color = table.shallow_copy(data.color)
  -- temporary?
  alt_color.b = 0.7
  tool.alt_selection_color = alt_color
  tool.alt_selection_cursor_box_type = data.selection_box
  selection_tools[#selection_tools+1] = tool]]
