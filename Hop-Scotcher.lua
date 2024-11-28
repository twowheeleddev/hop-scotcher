--[[ 
Install script to ~/.local/share/vlc/lua/extensions/credit-skipper.lua
Profiles saved to: ~/.config/vlc/credit-skipper.conf 
--]] -- Descriptor function
function descriptor()
    return {
        title = "Hop Scotcher",
        version = "1.1.0",
        author = "Douglas Green (Enhanced by AI)",
        url = "https://www.github.com/twowheeleddev/Hop-Scotcher",
        shortdesc = "Skip Intro/Outro Credits",
        description = "Automatically skip intro/outro credit sequences in VLC.",
        capabilities = {}
    }
end

-- Global variables
profiles = {}
config_file = vlc.config.configdir() .. "/Hop-Scotcher.conf"
script_enabled = true

-- Activate function
function activate()
    if file_exists(config_file) then load_all_profiles() end
    open_dialog()
end

-- Deactivate function
function deactivate() if dialog then dialog:delete() end end

-- Close function
function close() vlc.deactivate() end

-- Open dialog
function open_dialog()
    dialog = vlc.dialog(descriptor().title)

    -- Toggle On/Off Button
    dialog:add_button("Toggle Hop Scotcher: ON", toggle_script, 1, 1, 2, 1)

    -- UI for Profiles
    dialog:add_label("<center><h3>Profiles</h3></center>", 1, 1, 2, 1)
    profile_dropdown = dialog:add_dropdown(1, 2, 2, 1)
    dialog:add_button("Load", populate_profile_fields, 1, 3, 1, 1)
    dialog:add_button("Delete", delete_profile, 2, 3, 1, 1)

    dialog:add_label("", 1, 4, 2, 1) -- Spacer

    -- UI for Settings
    dialog:add_label("<center><h3>Settings</h3></center>", 1, 5, 2, 1)
    dialog:add_label("Profile name:", 1, 6, 1, 1)
    profile_name_input = dialog:add_text_input("", 2, 6, 1, 1)
    dialog:add_label("Intro duration (s):", 1, 7, 1, 1)
    start_time_input = dialog:add_text_input("", 2, 7, 1, 1)
    dialog:add_label("Outro duration (s):", 1, 8, 1, 1)
    finish_time_input = dialog:add_text_input("", 2, 8, 1, 1)
    dialog:add_button("Save", save_profile, 1, 9, 2, 1)

    -- Playlist Control
    dialog:add_label("", 1, 10, 2, 1) -- Spacer
    dialog:add_label(
        "<center><strong>Ensure your playlist is queued<br>before pressing start.</strong></center>",
        1, 11, 2, 1)
    dialog:add_button("Start Playlist", start_playlist, 1, 12, 2, 1)

    populate_profile_dropdown()
    populate_profile_fields()
end

-- Toggle script on/off
function toggle_script()
    script_enabled = not script_enabled
    local button_label = script_enabled and "Toggle Script: ON" or
                             "Toggle Script: OFF"
    dialog:del_widget_at(1, 1) -- Remove the existing button
    dialog:add_button(button_label, toggle_script, 1, 1, 2, 1) -- Add updated button
    vlc.msg.info("Script toggled " .. (script_enabled and "ON" or "OFF"))
end

-- Populate the profile dropdown
function populate_profile_dropdown()
    profile_dropdown:clear()
    for i, profile in ipairs(profiles) do
        profile_dropdown:add_value(profile.name, i)
    end
end

-- Populate profile fields based on the selected profile
function populate_profile_fields()
    local profile_index = profile_dropdown:get_value()
    local profile = profiles[profile_index]

    if profile then
        profile_name_input:set_text(profile.name)
        start_time_input:set_text(tostring(profile.start_time))
        finish_time_input:set_text(tostring(profile.finish_time))
    else
        clear_fields()
    end
end

-- Clear profile input fields
function clear_fields()
    profile_name_input:set_text("")
    start_time_input:set_text("")
    finish_time_input:set_text("")
end

-- Save or update a profile
function save_profile()
    local name = profile_name_input:get_text()
    local start_time = tonumber(start_time_input:get_text()) or 0
    local finish_time = tonumber(finish_time_input:get_text()) or 0

    if name == "" then
        vlc.msg.warn("Profile name cannot be empty!")
        return
    end

    for _, profile in ipairs(profiles) do
        if profile.name == name then
            profile.start_time = start_time
            profile.finish_time = finish_time
            save_all_profiles()
            return
        end
    end

    table.insert(profiles, {
        name = name,
        start_time = start_time,
        finish_time = finish_time
    })
    save_all_profiles()
end

-- Delete the selected profile
function delete_profile()
    local profile_index = profile_dropdown:get_value()
    if profile_index and profiles[profile_index] then
        table.remove(profiles, profile_index)
        save_all_profiles()
    end
end

-- Start the playlist with skipping logic
function start_playlist()
    if not script_enabled then
        vlc.msg.warn(
            "Script is toggled OFF. Enable the script to use this functionality.")
        return
    end

    local skip_start = tonumber(start_time_input:get_text()) or 0
    local skip_finish = tonumber(finish_time_input:get_text()) or 0
    local playlist = vlc.playlist.get("playlist", false)

    if not playlist or not playlist.children then
        vlc.msg.warn("No playlist found!")
        return
    end

    local valid_tracks = {}
    for _, item in ipairs(playlist.children) do
        if item.duration and item.duration > 0 then
            table.insert(valid_tracks, item)
        end
    end

    vlc.playlist.clear()

    for _, item in ipairs(valid_tracks) do
        local options = {}
        if item.duration > skip_start + skip_finish then
            if skip_start > 0 then
                table.insert(options, "start-time=" .. skip_start)
            end
            if skip_finish > 0 then
                table.insert(options,
                             "stop-time=" .. (item.duration - skip_finish))
            end
        end
        vlc.playlist.enqueue({{path = item.path, options = options}})
    end

    vlc.playlist.play()
end

-- Save all profiles to the config file
function save_all_profiles()
    local file = io.open(config_file, "w")
    if not file then
        vlc.msg.err("Could not save profiles!")
        return
    end

    for _, profile in ipairs(profiles) do
        file:write(string.format("%s=%d,%d\n", profile.name, profile.start_time,
                                 profile.finish_time))
    end

    file:close()
    populate_profile_dropdown()
end

-- Load profiles from the config file
function load_all_profiles()
    local file = io.open(config_file, "r")
    if not file then return end

    for line in file:lines() do
        local name, start_time, finish_time = string.match(line,
                                                           "([^=]+)=(%d+),(%d+)")
        if name and start_time and finish_time then
            table.insert(profiles, {
                name = name,
                start_time = tonumber(start_time),
                finish_time = tonumber(finish_time)
            })
        end
    end

    file:close()
end

-- Check if a file exists
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end
