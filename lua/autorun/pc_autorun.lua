AddCSLuaFile()

CASE_INVENTORY = true
CASE_INVENTORY_STACK = 32
CASE_INVENTORY_DEBUG = true
CASE_INVENTORY_SIZE_DEFAULT = {
    10, 6
}
--[[
    For each item stored in inventory (in order)
    uint8 X
    uint8 Y
    uint1 Rotated
]]
CASE_COMMAND_SYNC = 1

--[[
    uint16 invId
    uint16 count
    uint1 sync
]]
CASE_COMMAND_DROP = 2
--[[
    uint16 invId
    uint1 sync
]]
CASE_COMMAND_USE = 3
--[[
    uint16 srcID
    uint16 destID
]]
CASE_COMMAND_MERGE = 4


CaseInventory = {}
CaseInventory.ItemRegister = {}
CaseInventory.Inventories = {}

if CLIENT and not CaseInventory.Ready then
    CaseInventory.Ready = false
end


local server = {
    "server/sv_cvar.lua",
    "server/sv_hooks.lua",
    "server/sv_player.lua",
    "server/sv_network.lua"
}

local client = {
    "client/cl_player.lua",
    --"client/vgui/cl_gui.lua",
    --"client/vgui/cl_invpanel.lua",
    "client/cl_network.lua",
    "client/cl_guifont.lua"
}

local shared = {
    "shared/sh_api.lua",
    "shared/sh_items.lua",
    "shared/sh_hooks.lua"
}


local function _client(files)

    for _, v in pairs(files) do
        if CLIENT then
            include("playercase/" .. v)
        end

        if SERVER then
            AddCSLuaFile("playercase/" .. v)
        end

        if CASE_INVENTORY_DEBUG then
            print("Adding client file " .. v)
        end
    end
end

local function _server(files)
    for _, v in pairs(files) do
        if SERVER then
            include("playercase/" .. v)
        end


        if CASE_INVENTORY_DEBUG then
            print("Adding server file " .. v)
        end
    end
end


if SERVER then
    _server(server)
    _server(shared)
end

if CLIENT then
    _client(client)
    _client(shared)
end

if SERVER then
    util.AddNetworkString("CaseSync")         -- Server -> Client only full inventory sync
    util.AddNetworkString("CaseCommandEvent") -- Bidirectional commands
end
