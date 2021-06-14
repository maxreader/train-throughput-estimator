-- Junction size
-- Selection type, per player_data
-- TODO: possibly allow junction size as a setting even though it could potentially require recalculation of data if it exceeds previous maximum
-- TODO: locale for setting and shortcut
data:extend({
    --[[{type = "int-setting",
name = "tte-max-junction-size",
setting_type = "runtime-per-user",
default_value = 128,
minimum_value = 
},]]
    {
        type = "string-setting",
        name = "tte-selection-mode",
        setting_type = "runtime-per-user",
        default_value = "Entities",
        allowed_values = {"Entities", "Trains"}
    }
})
