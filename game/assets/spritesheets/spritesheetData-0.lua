--
-- created with TexturePacker - https://www.codeandweb.com/texturepacker
--
-- $TexturePacker:SmartUpdate:4c800f99e982df55cf1bebbb0c3cc575:b9d3ccc125cc3dcc8d53c380c65b6484:2f4514b1606dca30b9de45d22b279bf6$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- overlayForest
            x=20,
            y=0,
            width=28,
            height=28,

            sourceX = 2,
            sourceY = 0,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- overlayMountain
            x=0,
            y=28,
            width=28,
            height=28,

            sourceX = 1,
            sourceY = 0,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- overlayPostOffice
            x=0,
            y=0,
            width=20,
            height=24,

            sourceX = 6,
            sourceY = 4,
            sourceWidth = 32,
            sourceHeight = 32
        },
        {
            -- overlayTestPerson
            x=28,
            y=28,
            width=18,
            height=30,

            sourceX = 7,
            sourceY = 2,
            sourceWidth = 32,
            sourceHeight = 32
        },
    },

    sheetContentWidth = 48,
    sheetContentHeight = 58
}

SheetInfo.frameIndex =
{

    ["overlayForest"] = 1,
    ["overlayMountain"] = 2,
    ["overlayPostOffice"] = 3,
    ["overlayTestPerson"] = 4,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
