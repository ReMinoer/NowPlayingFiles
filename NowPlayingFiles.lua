-- Plugin description

local pluginId = "NowPlayingFiles"
local pluginDisplayName = "Now Playing Files"

function descriptor()
    return {
        title = pluginId,
        version = "1.0.0",
        author = "ReMinoer",
        shortdesc = pluginDisplayName,
        description = "Outputs playing song metadata and covers in files.",
        capabilities = { "input-listener" }
    }
end

-- Activation triggers

function activate()
    log("Activate")
    writeFiles()
end
function close()
    log("Close")
    clearFiles()
end
function deactivate()
    log("Deactivate")
    clearFiles()
end

-- Input changed triggers

function input_changed()
    if vlc.input.is_playing() then
        writeFiles()
    else
        clearFiles()
    end
end

function meta_changed()
end

-- Implementation
-- See: https://github.com/videolan/vlc/blob/468e3c8053bee61646aec83bb31466be3b08fc3a/modules/lua/libs/input.c#L148

function writeFiles()
    log("Write files")

    local item = vlc.item or vlc.input.item()
    local metas = item:metas()

    local radioMeta = {}
    local artistOrAlbumMeta = nil

    -- Title
    local meta = metas["title"]
    if not isNotEmpty(meta) then
        meta = item:name()
    end

    table.insert(radioMeta, meta)
    createMetaFile("title", meta)
    
    -- Artist
    meta = generateMetaFile(metas, "artist")
    if isNotEmpty(meta) then
        table.insert(radioMeta, meta)
        artistOrAlbumMeta = meta
    end
    
    -- Album
    meta = generateMetaFile(metas, "album")
    if isNotEmpty(meta) then
        table.insert(radioMeta, meta)
        if not isNotEmpty(artistOrAlbumMeta) then
            artistOrAlbumMeta = meta
        end
    end

    -- Artwork
    meta = generateMetaFile(metas, "artwork_url")
    copyArtworkFile("artwork", meta)

    -- Artist or Album
    createMetaFile("artistOrAlbum", artistOrAlbumMeta)

    -- Radio
    radioMeta = table.concat(radioMeta, " - ")
    createMetaFile("radio", radioMeta)
    
    -- Others
    generateMetaFile(metas, "track_number")
    generateMetaFile(metas, "genre")
    generateMetaFile(metas, "show_name")
    generateMetaFile(metas, "season")
    generateMetaFile(metas, "episode")
    generateMetaFile(metas, "actors")
    generateMetaFile(metas, "director")
    generateMetaFile(metas, "publisher")
    generateMetaFile(metas, "track_id")
    generateMetaFile(metas, "track_total")
    generateMetaFile(metas, "url")
    generateMetaFile(metas, "date")
    generateMetaFile(metas, "language")
    generateMetaFile(metas, "copyright")
    generateMetaFile(metas, "description")
    generateMetaFile(metas, "encoded_by")
    generateMetaFile(metas, "rating")
end

function clearFiles()
    log("Clear files")

    -- Audio
    clearMetaFile("title")
    clearMetaFile("artist")
    clearMetaFile("album")
    clearMetaFile("artwork_url")
    clearArtworkFile("artwork")
    clearMetaFile("track_number")
    clearMetaFile("genre")

    -- Video
    clearMetaFile("show_name")
    clearMetaFile("season")
    clearMetaFile("episode")
    clearMetaFile("actors")
    clearMetaFile("director")
    clearMetaFile("publisher")
    clearMetaFile("track_id")
    clearMetaFile("track_total")

    -- Misc
    clearMetaFile("url")
    clearMetaFile("date")
    clearMetaFile("language")
    clearMetaFile("copyright")
    clearMetaFile("description")
    clearMetaFile("encoded_by")
    clearMetaFile("rating")

    -- Combined
    clearMetaFile("artistOrAlbum")
    clearMetaFile("full")
end

-- Helpers

function generateMetaFile(metas, tag)
    local meta = metas[tag]
    createMetaFile(tag, meta)
    return meta
end

function createMetaFile(tag, content)
    if content then
        log(tag .. ": " .. content)
        createFile(tag .. ".txt", "w+", " " .. content .. " ")
    else
        createFile(tag .. ".txt", "w+")
    end
end

function copyArtworkFile(fileName, fileToCopyPath)
    local bytes
    if fileToCopyPath then
        local path = decodeWebAdress(fileToCopyPath)
        log(fileName .. ": " .. path)

        local file = io.open(path, "rb")
        if file then
            bytes = file:read("*a")
            file:close()
        end
    end
    createFile(fileName .. ".jpg", "wb+", bytes)
end

function clearMetaFile(fileName)
    createFile(fileName .. ".txt", "w+")
end

function clearArtworkFile(fileName)
    createFile(fileName .. ".jpg", "wb+")
end

function createFile(fileName, mode, content)
    local file = io.open(vlc.config.userdatadir() .. "\\nowplaying_" .. fileName, mode)
    if content then
        file:write(content)
    end
    file:close()
end

function isNotEmpty(text)
    return text and text ~= ""
end

function decodeWebAdress(adress)
    adress = adress:gsub("file:///", "")
    local result = ""
    local i = 1
    log(string.len(adress))
    while i <= string.len(adress) do
        log(i)
        log(result)
        local c = adress:sub(i, i)
        if c == "%" then
            local hex = adress:sub(i + 1, i + 2)
            result = result .. string.char(tonumber(hex, 16))
            i = i + 2
        else
            result = result .. c
        end
        i = i + 1
    end
    return result
end

function log(message)
    vlc.msg.err(pluginId .. " - " .. message)
end