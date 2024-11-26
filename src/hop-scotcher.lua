local descriptor = require("src.hop-descriptor")
local dialog = require("src.hop-dialog")
local maps = require("src.hop-maps")
local playlist = require("src.hop-playlist")
local utils = require("src.hop-utils")

local active = false

function descriptor() return descriptor.get() end

function activate()
    if active then
        deactivate()
        return
    end
    active = true
    maps.load_all()
    dialog.open()
end

function deactivate()
    active = false
    dialog.close()
end

function close() vlc.deactivate() end

function meta_changed() end
