local utils = {}

function utils.file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

function utils.read_profiles(file)
    local profiles = {}
    for line in io.lines(file) do
        local name, hop_in_time, hop_out_time = line:match("(.+)=(%d+),(%d+)")
        table.insert(profiles, {
            name = name,
            hop_in_time = tonumber(hop_in_time),
            hop_out_time = tonumber(hop_out_time)
        })
    end
    return profiles
end

function utils.write_profiles(file, profiles)
    local f = io.open(file, "w")
    for _, profile in pairs(profiles) do
        f:write(profile.name, "=", profile.hop_in_time, ",",
                profile.hop_out_time, "\n")
    end
    f:close()
end

return utils
