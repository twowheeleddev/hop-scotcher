--[[ 
    Hop Scotcher - A VLC extension for hopping over custom video sections (intro/outro).
    Author: Douglas Green
    Version: 2.0.0

    This script provides a user interface for setting hop-in and hop-out times in minutes and seconds.
    Users can save, load, and delete hop maps (profiles) for faster setups.

    PLEASE NOTE: THIS FILE IS JUST A CONSOLIDATION OF ALL THE OTHER FILES INSIDE THE SRC DIRECTORY. i HAVE DONE THIS AS I WAS UNABLE TO GET VLC TO RECOGNIZE HOP SCOTCHER WHILE IN A SUBDIRECTORY. THIS IS A QUICK FIX AND IN THE FUTURE I MAY RETURN TO THE MODULAR SETUP AS I FEEL IT IS WAY MORE MANAGEABLE AND ELEGANT. ENJOY!
    
]] --[[ ========= IMPORTS AND GLOBAL VARIABLES ========= ]] local vlc = vlc
local profiles = {} -- Table to store Hop Maps (profiles)
local config_file = vlc.config.configdir() .. "/hop-scotcher.conf" -- Configuration file path
local dialog_instance = nil -- Dialog instance

--[[ ========= UTILITY FUNCTIONS ========= ]]
-- Convert time string (m:s) to total seconds
local function time_to_seconds(time_str)
    local minutes, seconds = time_str:match("(%d+):(%d+)")
    return tonumber(minutes) * 60 + tonumber(seconds)
end

-- Convert seconds to time string (m:s)
local function seconds_to_time(total_seconds)
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- Read profiles from the configuration file
local function read_profiles()
    local file = io.open(config_file, "r")
    if not file then return {} end

    local lines = {}
    for line in file:lines() do
        local name, hop_in_time, hop_out_time = line:match("(.+)=(%d+),(%d+)")
        if name and hop_in_time and hop_out_time then
            table.insert(lines, {
                name = name,
                hop_in_time = tonumber(hop_in_time),
                hop_out_time = tonumber(hop_out_time)
            })
        end
    end
    file:close()
    return lines
end

-- Write profiles to the configuration file
local function write_profiles()
    local file = io.open(config_file, "w")
    for _, profile in ipairs(profiles) do
        file:write(profile.name, "=", profile.hop_in_time, ",",
                   profile.hop_out_time, "\n")
    end
    file:close()
end

--[[ ========= DIALOG FUNCTIONS ========= ]]
local function populate_time_dropdowns(minute_dropdown, second_dropdown)
    for i = 0, 59 do
        local value = (i < 10) and ("0" .. i) or tostring(i)
        minute_dropdown:add_value(value, i)
        second_dropdown:add_value(value, i)
    end
end

local function open_dialog()
    -- Create the dialog
    local dlg = vlc.dialog("Hop Scotcher")
    dialog_instance = dlg

    -- Section: Hop Paths
    dlg:add_label("<center><h2>Hop Paths</h2></center>", 1, 1, 4, 1)
    local preset_dropdown = dlg:add_dropdown(1, 2, 2, 1)
    dlg:add_button("Load Hop Path", function()
        local idx = preset_dropdown:get_value()
        if not idx then return end
        local profile = profiles[idx]
        dlg:get_widget("hop_map_name"):set_text(profile.name)
        dlg:get_widget("hop_in_minutes"):set_value(math.floor(
                                                       profile.hop_in_time / 60))
        dlg:get_widget("hop_in_seconds"):set_value(profile.hop_in_time % 60)
        dlg:get_widget("hop_out_minutes"):set_value(math.floor(
                                                        profile.hop_out_time /
                                                            60))
        dlg:get_widget("hop_out_seconds"):set_value(profile.hop_out_time % 60)
    end, 3, 2, 1, 1)
    dlg:add_button("Delete Hop Path", function()
        local idx = preset_dropdown:get_value()
        if not idx then return end
        table.remove(profiles, idx)
        write_profiles()
    end, 4, 2, 1, 1)

    -- Section: Settings
    dlg:add_label("<center><h2>Settings</h2></center>", 1, 3, 4, 1)
    dlg:add_label("Hop Map Name:", 1, 4, 1, 1)
    dlg:add_text_input("", 2, 4, 3, 1, "hop_map_name")

    dlg:add_label("Hop-In Time (m:s):", 1, 5, 1, 1)
    local hop_in_minutes = dlg:add_dropdown(2, 5, 1, 1, "hop_in_minutes")
    local hop_in_seconds = dlg:add_dropdown(3, 5, 1, 1, "hop_in_seconds")
    populate_time_dropdowns(hop_in_minutes, hop_in_seconds)

    dlg:add_label("Hop-Out Time (m:s):", 1, 6, 1, 1)
    local hop_out_minutes = dlg:add_dropdown(2, 6, 1, 1, "hop_out_minutes")
    local hop_out_seconds = dlg:add_dropdown(3, 6, 1, 1, "hop_out_seconds")
    populate_time_dropdowns(hop_out_minutes, hop_out_seconds)

    dlg:add_button("Save Hop Map", function()
        local name = dlg:get_widget("hop_map_name"):get_text()
        if name == "" then return end
        local hop_in_time = hop_in_minutes:get_value() * 60 +
                                hop_in_seconds:get_value()
        local hop_out_time = hop_out_minutes:get_value() * 60 +
                                 hop_out_seconds:get_value()

        -- Update existing or add new profile
        for _, profile in ipairs(profiles) do
            if profile.name == name then
                profile.hop_in_time = hop_in_time
                profile.hop_out_time = hop_out_time
                write_profiles()
                return
            end
        end
        table.insert(profiles, {
            name = name,
            hop_in_time = hop_in_time,
            hop_out_time = hop_out_time
        })
        write_profiles()
    end, 1, 7, 4, 1)

    -- Section: Playlist
    dlg:add_label("<center><h2>Playlist</h2></center>", 1, 8, 4, 1)
    dlg:add_button("Start Hopping", function()
        local items = vlc.playlist.get("playlist", false).children
        vlc.playlist.clear()

        local hop_in_time = hop_in_minutes:get_value() * 60 +
                                hop_in_seconds:get_value()
        local hop_out_time = hop_out_minutes:get_value() * 60 +
                                 hop_out_seconds:get_value()

        for _, item in ipairs(items) do
            local options = {}
            if hop_in_time > 0 then
                table.insert(options, "start-time=" .. hop_in_time)
            end
            if item.duration > hop_out_time then
                table.insert(options,
                             "stop-time=" .. (item.duration - hop_out_time))
            end
            vlc.playlist.enqueue({{path = item.path, options = options}})
        end
        vlc.playlist.play()
    end, 1, 9, 2, 1)
    dlg:add_button("Stop Hopping", function() vlc.playlist.stop() end, 3, 9, 2,
                   1)
end

local function close_dialog()
    if dialog_instance then dialog_instance:delete() end
end

--[[ ========= VLC EXTENSION FUNCTIONS ========= ]]
function descriptor()
    return {
        title = "Hop Scotcher",
        version = "2.0.0",
        author = "Douglas Green",
        description = "Hop over intro and outro sections in VLC playlists.",
        capabilities = {}
    }
end

function activate()
    profiles = read_profiles()
    open_dialog()
end

function deactivate() close_dialog() end

function close() vlc.deactivate() end
