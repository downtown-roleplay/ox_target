--[[
╔══════════════════════════════════════════════════════════════╗
║        ox_target — client/framework/rsg.lua                  ║
║                                                              ║
║  Framework module for RSG Core (Rexshack-RedM) via          ║
║  CoreBridge_RSG compatibility layer.                         ║
║                                                              ║
║  Auto-detected by ox_target when exports['rsg-core']        ║
║  :GetCoreObject() exists.                                    ║
║                                                              ║
║  CONTEXTO: client                                            ║
╚══════════════════════════════════════════════════════════════╝
]]

local RSGCore = exports['rsg-core']:GetCoreObject()
local utils = require 'client.utils'
local playerItems = utils.getItems()
local usingOxInventory = utils.hasExport('ox_inventory.Items')

-- Inicializa grupos locais
local playerJob = {}
local playerGang = {}

local function setPlayerData(playerData)
    playerJob = playerData.job or {}
    playerGang = playerData.gang or {}

    if usingOxInventory or not playerData.items then return end

    table.wipe(playerItems)
    for _, v in pairs(playerData.items) do
        if v.amount and v.amount > 0 then
            playerItems[v.name] = v.amount
        end
    end
end

-- Estado inicial
local initialData = RSGCore.Functions.GetPlayerData()
if initialData and next(initialData) then
    setPlayerData(initialData)
end

-- Evento de load do personagem
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function(PlayerData)
    if source ~= '' then return end
    if PlayerData then
        setPlayerData(PlayerData)
    end
end)

-- Evento de atualização de PlayerData
RegisterNetEvent('RSGCore:Player:SetPlayerData', function(val)
    if source ~= '' then return end
    if val then
        setPlayerData(val)
    end
end)

-- Evento de unload
RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    playerJob = {}
    playerGang = {}
    table.wipe(playerItems)
end)

--- Verifica se o jogador pertence ao(s) grupo(s) especificado(s).
--- Segue o mesmo padrão do ESX/QBCore: aceita string, array ou hash.
---@param filter string | string[] | table<string, number>
---@return boolean
function utils.hasPlayerGotGroup(filter)
    local _type = type(filter)

    if _type == 'string' then
        return filter == playerJob.name or filter == playerGang.name
    end

    if _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            -- { ['jobname'] = grade, ['gangname'] = grade }
            for name, grade in pairs(filter) do
                if playerJob.name == name and (playerJob.grade.level or 0) >= grade then
                    return true
                end
                if playerGang.name == name and (playerGang.grade.level or 0) >= grade then
                    return true
                end
            end
        elseif tabletype == 'array' then
            -- { 'jobname1', 'jobname2' }
            for i = 1, #filter do
                local name = filter[i]
                if name == playerJob.name or name == playerGang.name then
                    return true
                end
            end
        end
    end

    return false
end
