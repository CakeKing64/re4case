AddCSLuaFile()

CASE_INVENTORY = true
CASE_INVENTORY_DEBUG = true

CaseInventory = {}

local serverLua = {
    "server/sv_item_interact.lua",
    "server/sv_player_spawn.lua",
    "server/sv_net.lua",
    "server/sv_functions.lua"
}

local clientLua = {
    "client/cl_item_interact.lua",
    "client/cl_net.lua"
}

local sharedLua = {
    "shared/sh_player.lua"
}

local function _include(table)
    for _, v in pairs(table) do
        include("caseinventory/" .. v)
    end
end

local function _cslua(table)
    for _, v in pairs(table) do
        AddCSLuaFile("caseinventory/" .. v)
    end
end


if SERVER then
    _include(serverLua)
    _include(sharedLua)

    CaseInventory:SetupNetworkStrings()
end

_cslua(clientLua)
_cslua(sharedLua)


if CLIENT then
    _include(clientLua)
    _include(sharedLua)
end