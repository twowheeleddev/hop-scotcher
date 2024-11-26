local playlist = {}
local maps = require("hop-maps")

function playlist.start()
    local hop_in_time = maps.hop_in_minute_dropdown:get_value() * 60 +
                            maps.hop_in_second_dropdown:get_value()
    local hop_out_time = maps.hop_out_minute_dropdown:get_value() * 60 +
                             maps.hop_out_second_dropdown:get_value()

    local items = vlc.playlist.get("playlist", false).children
    vlc.playlist.clear()

    for _, item in ipairs(items) do
        if item.duration then
            local options = {}
            if hop_in_time > 0 then
                table.insert(options, "start-time=" .. hop_in_time)
            end
            if hop_out_time > 0 and item.duration > hop_out_time then
                table.insert(options,
                             "stop-time=" .. (item.duration - hop_out_time))
            end
            vlc.playlist.enqueue({{path = item.path, options = options}})
        end
    end

    vlc.playlist.play()
end

function playlist.stop() vlc.playlist.stop() end

return playlist
