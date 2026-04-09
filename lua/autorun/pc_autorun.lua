AddCSLuaFile()

CASE_INVENTORY = true
CASE_INVENTORY_STACK = 32
CASE_INVENTORY_DEBUG = false
CASE_INVENTORY_SIZE_DEFAULT = {
	10, 6
}

CASE_SIZES = {
	S = {10, 6},
	M = {11, 7},
	L = {12, 8},
	XL = {15, 8},
	XXL = {15, 10}
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
--[[
	uint16 itemID
	bool delete
	string modelName
	int16 sizeW
	int16 sizeH
	float scale
	float offsetX
	float offsetY
	float offsetZ
	float rotationX
	float rotationY
	float rotationZ
]]
CASE_COMMAND_SYNC_OVERRIDES = 5

--[[
	No args :)
	Is resticted to one time per player
	(Player.HasSyncedOverrides)
]]
CASE_COMMAND_REQUEST_OVERRIDES = 6


CaseInventory = {}
CaseInventory.ItemRegister = {}
CaseInventory.RegisterOverrides = {}
CaseInventory.Inventories = {}
CaseInventory.PickupQueue = {}

if SERVER then
	-- To allow saving overrides that don't exist any more
	CaseInventory.GhostOverrides = {}
end

if CLIENT then
	CaseInventory.ItemRegisterLayout = {}
	CaseInventory.ItemRegisterApply = false
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
	"client/cl_guifont.lua",
	"client/cl_editor.lua"
}

local shared = {
	"shared/sh_api.lua",
	"shared/sh_items.lua",
	"shared/sh_hooks.lua",
	"item_list.lua"
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

_client(client)
_client(shared)

if SERVER then
	util.AddNetworkString("CaseSync")         -- Server -> Client only full inventory sync
	util.AddNetworkString("CaseCommandEvent") -- Bidirectional commands
	util.AddNetworkString("CaseSyncIDs")      -- Server -> Client sync item ids
	util.AddNetworkString("CaseSyncOverride") -- Server -> Client
	util.AddNetworkString("CaseOnPickup") -- Server -> Client
end
