QBX = QBX or {}
QBX.PlayerData = QBX.PlayerData or {}

local function refresh()
    if GetResourceState('qbx_core') ~= 'started' then return end
    local ok, data = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if ok and data then QBX.PlayerData = data end
end

CreateThread(function()
    Wait(250)
    refresh()
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', refresh)
AddEventHandler('QBCore:Player:SetPlayerData', function(data)
    QBX.PlayerData = data or {}
end)
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    QBX.PlayerData = {}
end)
