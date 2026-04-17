local fntLoader = {}

---@class FntSpec
---@field common FntSpecCommon
---@field pages {[integer]: string}
---@field chars {[integer]: FntSpecChar}
---@field kernings {[integer]: {[integer]: integer}}
---@field charCount integer
---@field pageCount integer

---@class FntSpecCommon
---@field lineHeight integer
---@field base integer
---@field scaleW integer
---@field scaleH integer
---@field pages integer

---@class FntSpecChar
---@field x integer
---@field y integer
---@field width integer
---@field height integer
---@field xoffset integer
---@field yoffset integer
---@field xadvance integer
---@field page integer

---@class FntSpecKerningPair
---@field left integer
---@field right integer

---@param params string
---@return table
local function parseParams(params)
    local kv = {}
    local quotedPairs = '([%w_%-]+)%s*=%s*"([^"]*)"'
    local unquotedPairs = '([%w_%-]+)%s*=%s*([^%s"]+)'

    for key, value in params:gmatch(quotedPairs) do
        kv[key] = value
    end

    for key, value in params:gmatch(unquotedPairs) do
        kv[key] = value
    end

    return kv
end

---@return FntSpec
local function newEmptySpec()
    return {
        common = {
            lineHeight = 0,
            base = 0,
            scaleW = 0,
            scaleH = 0,
            pages = 1,
        },
        pages = {},
        chars = {},
        kernings = {},
        charCount = 0,
        pageCount = 0,
    }
end

---@param file file*
---@return FntSpec?, string?
local function parseFnt(file)
    local fnt = newEmptySpec()

    for line in file:lines() do
        local tag, rawParams = line:match("^(%S+)%s*(.*)$")
        if tag then
            local params = parseParams(rawParams or "")

            if tag == "common" then
                fnt.common.lineHeight = tonumber(params.lineHeight) or fnt.common.lineHeight
                fnt.common.base = tonumber(params.base) or fnt.common.base
                fnt.common.scaleW = tonumber(params.scaleW) or fnt.common.scaleW
                fnt.common.scaleH = tonumber(params.scaleH) or fnt.common.scaleH
                fnt.common.pages = tonumber(params.pages) or fnt.common.pages
            elseif tag == "page" then
                local id = tonumber(params.id) or 0
                fnt.pages[id] = params.file
                fnt.pageCount = fnt.pageCount + 1
            elseif tag == "char" then
                local id = tonumber(params.id)
                if id then
                    fnt.chars[id] = {
                        x = tonumber(params.x) or 0,
                        y = tonumber(params.y) or 0,
                        width = tonumber(params.width) or 0,
                        height = tonumber(params.height) or 0,
                        xoffset = tonumber(params.xoffset) or 0,
                        yoffset = tonumber(params.yoffset) or 0,
                        xadvance = tonumber(params.xadvance) or 0,
                        page = tonumber(params.page) or 0,
                    }
                    fnt.charCount = fnt.charCount + 1
                end
            elseif tag == "kerning" then
                local a = tonumber(params.first)
                local b = tonumber(params.second)
                local amount = tonumber(params.amount)
                if a and b and amount then
                    fnt.kernings[a] = fnt.kernings[a] or {}
                    fnt.kernings[a][b] = amount
                end
            end
        end
    end

    if fnt.charCount == 0 then
        return nil, "No characters found in the FNT file. Make sure it's a TXT version of the BMFont format (not binary or XML)"
    end

    return fnt, nil
end

---@param path string
---@return string
local function dirOf(path)
    return path:match("^(.*)[/\\]") or "."
end

---@param directoryPath string
---@param file string
---@return Image?, string?
local function createImage(directoryPath, file)
    local pagePath =  app.fs.joinPath(directoryPath, file)
    local ok, imgOrErr = pcall(function() return Image{ fromFile = pagePath } end)

    if not ok or not imgOrErr then
        local details = imgOrErr and " (" .. tostring(imgOrErr) .. ")" or ""
        return nil, "Failed to load page: " .. pagePath .. details
    end

    return imgOrErr
end

---@param fntPath string
---@return FntSpec?, Image[]?, string?
function fntLoader.loadPath(fntPath)
    local fntFile, err = io.open(fntPath, "r")
    if not fntFile then return nil, nil, err end

    local fntSpec, err = parseFnt(fntFile)
    fntFile:close()
    if not fntSpec then return nil, nil, err end

    local fntDirPath = dirOf(fntPath)
    ---@type Image[]
    local pages = {}
    for id, file in pairs(fntSpec.pages) do
        pages[id], err = createImage(fntDirPath, file)
        if not pages[id] then return nil, nil, err end
    end

    return fntSpec, pages, nil
end

return fntLoader
