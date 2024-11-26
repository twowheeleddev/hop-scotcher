local maps = {}
local utils = require("hop-utils")

maps.data = {}
maps.config_file = vlc.config.configdir() .. "/hop-scotcher.conf"

function maps.load_all()
    if not utils.file_exists(maps.config_file) then return end
    maps.data = utils.read_profiles(maps.config_file)
end

function maps.save()
    local name = maps.name_input:get_text()
    local hop_in_time = maps.hop_in_minute_dropdown:get_value() * 60 +
                            maps.hop_in_second_dropdown:get_value()
    local hop_out_time = maps.hop_out_minute_dropdown:get_value() * 60 +
                             maps.hop_out_second_dropdown:get_value()

    if name == "" then return end

    for _, map in pairs(maps.data) do
        if map.name == name then
            map.hop_in_time = hop_in_time
            map.hop_out_time = hop_out_time
            utils.write_profiles(maps.config_file, maps.data)
            return
        end
    end

    table.insert(maps.data, {
        name = name,
        hop_in_time = hop_in_time,
        hop_out_time = hop_out_time
    })
    utils.write_profiles(maps.config_file, maps.data)
end

function maps.populate_presets()
    maps.preset_dropdown:clear()
    for i, map in ipairs(maps.data) do
        maps.preset_dropdown:add_value(map.name, i)
    end
end

function maps.load_preset()
    local idx = maps.preset_dropdown:get_value()
    if not idx then return end

    local map = maps.data[idx]
    maps.name_input:set_text(map.name)
    maps.hop_in_minute_dropdown:set_value(math.floor(map.hop_in_time / 60))
    maps.hop_in_second_dropdown:set_value(map.hop_in_time % 60)
    maps.hop_out_minute_dropdown:set_value(math.floor(map.hop_out_time / 60))
    maps.hop_out_second_dropdown:set_value(map.hop_out_time % 60)
end

function maps.delete_preset()
    local idx = maps.preset_dropdown:get_value()
    if not idx then return end

    table.remove(maps.data, idx)
    utils.write_profiles(maps.config_file, maps.data)
    maps.populate_presets()
end

return maps
