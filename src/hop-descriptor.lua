local descriptor = {}

function descriptor.get()
    return {
        title = "Hop Scotcher",
        version = "2.0.0",
        author = "Douglas Green",
        shortdesc = "Hop Over Video Sections",
        description = "Define and hop over custom video sections in a VLC playlist with minute/second precision.",
        capabilities = {}
    }
end

return descriptor
