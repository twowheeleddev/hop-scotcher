--[[ 
    Hop Scotcher - A VLC extension for skipping custom video sections.
    Author: Douglas Green
    Version: 2.1.0

    FEATURES:
    - Define hop-in and hop-out times using keyboard shortcuts.
    - Save times as profiles for reuse.
    - Provide visual feedback via the VLC UI and logs.

    NOTE:
    - Place this script in VLC's `lua/extensions` directory.
    - Activate via `View > Hop Scotcher` in VLC.
]] --[[ ========= IMPORTS AND GLOBAL VARIABLES ========= ]] local vlc = vlc -- Access VLC's Lua API.
local profiles = {} -- Stores saved hop maps (profiles).
local config_file = vlc.config.configdir() .. "/Hop-Scotcher.conf" -- Config file path.
local hop_in_time = nil -- Stores dynamically set hop-in time.
local hop_out_time = nil -- Stores dynamically set hop-out time.
local dialog_instance = nil -- Reference to the dialog instance.
local message_area = nil -- Reference to the text area for messages.

--[[ ========= UTILITY FUNCTIONS ========= ]]

-- Converts total seconds to a formatted time string (m:ss).
-- Example: 90 seconds becomes "1:30".
local function seconds_to_time(total_seconds)
    if not total_seconds then return "N/A" end -- Handle unset times.
    local minutes = math.floor(total_seconds / 60)
    local seconds = total_seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

-- Displays a message in the dialog or logs it if the dialog is unavailable.
-- This is the primary method for providing feedback to the user.
local function display_message(msg)
    if message_area then
        message_area:set_text(msg)
    else
        vlc.msg.info(msg) -- Fallback for when the dialog is not available.
    end
end

-- Saves the current hop-in and hop-out times as a profile.
-- Automatically generates a unique name for the profile.
local function save_dynamic_profile()
    if not hop_in_time or not hop_out_time then
        display_message("Both hop-in and hop-out times must be set!")
        return
    end
    local profile_name = "Quick Hop " .. os.date("%H:%M:%S") -- Unique name.
    table.insert(profiles, {
        name = profile_name,
        hop_in_time = hop_in_time,
        hop_out_time = hop_out_time
    })
    write_profiles() -- Persist the profiles to the configuration file.
    display_message("Profile '" .. profile_name .. "' saved successfully!")
end

-- Reads saved profiles from the configuration file.
-- Returns a table of profiles or an empty table if the file doesn't exist.
local function read_profiles()
    local file = io.open(config_file, "r")
    if not file then return {} end
    local profiles = {}
    for line in file:lines() do
        local name, hop_in, hop_out = line:match("(.+)=(%d+),(%d+)")
        if name and hop_in and hop_out then
            table.insert(profiles, {
                name = name,
                hop_in_time = tonumber(hop_in),
                hop_out_time = tonumber(hop_out)
            })
        end
    end
    file:close()
    return profiles
end

-- Writes all profiles to the configuration file.
-- Each profile is saved in the format: `name=hop_in_time,hop_out_time`.
local function write_profiles()
    local file = io.open(config_file, "w")
    for _, profile in ipairs(profiles) do
        file:write(profile.name, "=", profile.hop_in_time, ",",
                   profile.hop_out_time, "\n")
    end
    file:close()
end

--[[ ========= DIALOG FUNCTIONS ========= ]]

-- Opens the main dialog window for the extension.
local function open_dialog()
    local dlg = vlc.dialog("Hop Scotcher") -- Create the dialog instance.
    dialog_instance = dlg

    -- Messages Section
    dlg:add_label("<center><h2>Messages</h2></center>", 1, 1, 4, 1)
    message_area = dlg:add_text_input("", 1, 2, 4, 1)
    message_area:set_text("Welcome to Hop Scotcher!")

    -- Save Profile Section
    dlg:add_label("<center><h2>Dynamic Time Recording</h2></center>", 1, 3, 4, 1)
    dlg:add_button("Save Dynamic Profile", save_dynamic_profile, 1, 4, 4, 1)
end

-- Closes the dialog window.
local function close_dialog()
    if dialog_instance then
        dialog_instance:delete()
        dialog_instance = nil
    end
end

--[[ ========= KEYBOARD SHORTCUT HANDLER ========= ]]

-- Handles keyboard shortcuts to dynamically set hop-in and hop-out times.
-- The first press sets hop-in time; the second press sets hop-out time.
local function handle_keyboard_shortcut()
    local input = vlc.object.input() -- Get the current input object.
    if not input then
        display_message("No media is currently playing.")
        return
    end

    local current_time = vlc.var.get(input, "time") -- Get the current playback time.
    if not hop_in_time then
        hop_in_time = current_time
        display_message("Hop-In Time Set: " .. seconds_to_time(hop_in_time))
    elseif not hop_out_time then
        hop_out_time = current_time
        display_message("Hop-Out Time Set: " .. seconds_to_time(hop_out_time))
    else
        display_message("Both times are already set. Save the profile or reset.")
    end
end

--[[ ========= VLC EXTENSION FUNCTIONS ========= ]]

-- Descriptor provides metadata about the extension.
function descriptor()
    return {
        title = "Hop Scotcher",
        version = "2.3.0",
        author = "Douglas Green",
        description = "Hop over intro and outro sections in VLC playlists.",
        capabilities = {"input-listener"} -- Enable keyboard input handling.
    }
end

-- Activates the extension, initializes the dialog, and sets up event listeners.
function activate()
    profiles = read_profiles() -- Load saved profiles from the configuration file.
    vlc.var.add_callback(vlc.object.input(), "key-pressed",
                         handle_keyboard_shortcut) -- Listen for key presses.
    display_message("Hop Scotcher Activated! Use the shortcut to record times.")
    open_dialog() -- Open the main dialog window.
end

-- Deactivates the extension, removes event listeners, and closes the dialog.
function deactivate()
    vlc.var.del_callback(vlc.object.input(), "key-pressed",
                         handle_keyboard_shortcut) -- Stop listening for key presses.
    display_message("Hop Scotcher Deactivated. Goodbye!")
    close_dialog() -- Close the main dialog window.
end

-- Ensures the extension stops running properly.
function close() vlc.deactivate() end
