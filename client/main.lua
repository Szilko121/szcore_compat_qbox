local function adapt(d)
    if not d or not d.citizenid then return {} end
    local metadata = {}
    for k, v in pairs(d.metadata or {}) do metadata[k] = v end
    if metadata.isdead == nil then metadata.isdead = metadata.dead == true end
    return {
        source = d.source,
        citizenid = d.citizenid,
        name = d.name,
        money = d.money,
        charinfo = {
            firstname = d.charinfo.firstname,
            lastname = d.charinfo.lastname,
            birthdate = d.charinfo.birthdate,
            nationality = d.charinfo.nationality,
            cid = d.slot,
            gender = d.charinfo.gender == 'female' and 1 or 0,
            backstory = '', phone = '', account = '', card = 0
        },
        job = d.job and {
            name = d.job.name, label = d.job.label, payment = d.job.salary or 0, type = d.job.type,
            onduty = d.job.onduty == true, isboss = d.job.boss == true,
            grade = { name = d.job.gradeName, level = d.job.grade }
        } or {},
        jobs = d.job and d.job.name ~= 'unemployed' and { [d.job.name] = d.job.grade } or {},
        gang = d.gang and { name = d.gang.name, label = d.gang.label or d.gang.name or 'None', isboss = d.gang.boss == true, grade = { name = d.gang.gradeName or tostring(d.gang.grade or 0), level = tonumber(d.gang.grade) or 0 } } or { name = 'none', label = 'None', isboss = false, grade = { name = '0', level = 0 } },
        gangs = {}, position = d.position, metadata = metadata, cid = d.slot, items = {}
    }
end

exports('GetPlayerData', function() return adapt(exports.szcore:GetPlayerData()) end)

AddEventHandler('szcore:client:onPlayerLoaded', function(data)
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerEvent('QBCore:Player:SetPlayerData', adapt(data))
end)
AddEventHandler('szcore:client:onPlayerUnloaded', function()
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)
AddEventHandler('szcore:client:onPlayerData', function(path)
    local data = adapt(exports.szcore:GetPlayerData())
    TriggerEvent('QBCore:Player:SetPlayerData', data)
    if path == 'job' then TriggerEvent('QBCore:Client:OnJobUpdate', data.job) end
end)
