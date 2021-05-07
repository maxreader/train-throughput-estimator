local data_util = require("__flib__.data-util")

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
