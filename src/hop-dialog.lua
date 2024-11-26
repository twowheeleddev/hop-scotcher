local maps = require("hop-maps")
local playlist = require("hop-playlist")

local dialog = {}

function dialog.open()
    local dlg = vlc.dialog("Hop Scotcher")
    dialog.instance = dlg

    dlg:add_label("<center><h2>Hop Paths</h2></center>", 1, 1, 4, 1)

    maps.preset_dropdown = dlg:add_dropdown(1, 2, 2, 1)
    maps.populate_presets()

    dlg:add_button("Load Hop Path", maps.load_preset, 3, 2, 1, 1)
    dlg:add_button("Delete Hop Path", maps.delete_preset, 4, 2, 1, 1)

    dlg:add_label("<center><h2>Settings</h2></center>", 1, 3, 4, 1)

    dlg:add_label("Hop Map Name:", 1, 4, 1, 1)
    maps.name_input = dlg:add_text_input("", 2, 4, 3, 1)

    dlg:add_label("Hop-In Time (m:s):", 1, 5, 1, 1)
    maps.hop_in_minute_dropdown = dlg:add_dropdown(2, 5, 1, 1)
    maps.hop_in_second_dropdown = dlg:add_dropdown(3, 5, 1, 1)
    dialog.populate_time_dropdowns(maps.hop_in_minute_dropdown,
                                   maps.hop_in_second_dropdown)

    dlg:add_label("Hop-Out Time (m:s):", 1, 6, 1, 1)
    maps.hop_out_minute_dropdown = dlg:add_dropdown(2, 6, 1, 1)
    maps.hop_out_second_dropdown = dlg:add_dropdown(3, 6, 1, 1)
    dialog.populate_time_dropdowns(maps.hop_out_minute_dropdown,
                                   maps.hop_out_second_dropdown)

    dlg:add_button("Save Hop Map", maps.save, 1, 7, 4, 1)

    dlg:add_label("<center><h2>Playlist</h2></center>", 1, 8, 4, 1)

    dlg:add_button("Start Hopping", playlist.start, 1, 9, 2, 1)
    dlg:add_button("Stop Hopping", playlist.stop, 3, 9, 2, 1)
end

function dialog.close() if dialog.instance then dialog.instance:delete() end end

function dialog.populate_time_dropdowns(minute_dropdown, second_dropdown)
    for i = 0, 59 do
        if i < 10 then
            minute_dropdown:add_value("0" .. i, i)
            second_dropdown:add_value("0" .. i, i)
        else
            minute_dropdown:add_value(i, i)
            second_dropdown:add_value(i, i)
        end
    end
end

return dialog
