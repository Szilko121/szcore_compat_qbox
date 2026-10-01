local wrappers = {}

local function rawPlayer(identifier)
    if type(identifier) == 'number' or tonumber(identifier) then
        return exports.szcore:GetPlayer(tonumber(identifier))
    end
    return exports.szcore:GetPlayerByCitizenId(identifier)
end

local function qbxJob(job)
    return {
        name = job.name,
        label = job.label,
        payment = job.salary or 0,
        type = job.type,
        onduty = job.onduty == true,
        isboss = job.boss == true,
        grade = { name = job.gradeName, level = job.grade }
    }
end

local function qbxData(player)
    player=exports.szcore:GetPlayer(player.PlayerData.source) or player
    local d = player.PlayerData
    local metadata = {}
    for k, v in pairs(d.metadata or {}) do metadata[k] = v end
    if metadata.isdead == nil then metadata.isdead = metadata.dead == true end
    local jobs = {}
    for name,g in pairs((d.groups and d.groups.jobs) or {}) do jobs[name]=g.grade end
    return {
        source = d.source,
        citizenid = d.citizenid,
        license = d.license,
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
        job = qbxJob(d.job),
        jobs = jobs,
        gang = { name = d.gang.name, label = d.gang.name, isboss = false, grade = { name = tostring(d.gang.grade), level = d.gang.grade } },
        gangs = (function() local o={} for name,g in pairs((d.groups and d.groups.gangs) or {}) do o[name]=g.grade end return o end)(),
        position = d.position,
        metadata = metadata,
        cid = d.slot,
        items = (function()local out={};if GetResourceState('szcore_inventory')=='started' then local inv=exports.szcore_inventory:GetPlayerInventory(d.source);for slot,e in pairs(inv and inv.items or {})do out[slot]={name=e.name,amount=e.amount,info=e.metadata,slot=slot}end end;return out end)()
    }
end

local function wrap(player)
    if not player then return nil end
    local src = player.PlayerData.source
    if wrappers[src] and wrappers[src]._citizenid==player.PlayerData.citizenid then return wrappers[src] end

    local functions = {}
    functions.AddMoney = function(account, amount, reason) return player.addMoney(account, amount, reason) end
    functions.RemoveMoney = function(account, amount, reason) return player.removeMoney(account, amount, reason) end
    functions.SetMoney = function(account, amount, reason) return player.setMoney(account, amount, reason) end
    functions.GetMoney = function(account) return player.getMoney(account) end
    functions.SetJob = function(job, grade) return exports.szcore:ReplacePrimaryGroup(player.PlayerData.source,'jobs',job,grade) end
    functions.SetJobDuty = function(duty) return player.setDuty(duty) end
    functions.SetMetaData = function(key, value) return player.setMetadata(key, value) end
    functions.GetMetaData = function(key) return player.getMetadata(key) end
    functions.Save = function() return player.save(true) end
    functions.AddItem = function(item,amount,slot,info)
        local inv=GetResourceState('szcore_inventory')=='started' and exports.szcore_inventory:GetPlayerInventory(src)
        return inv and exports.szcore_inventory:AddItem(inv.inventory_id,item,amount,info,slot) or false
    end
    functions.RemoveItem = function(item,amount)
        local inv=GetResourceState('szcore_inventory')=='started' and exports.szcore_inventory:GetPlayerInventory(src)
        return inv and exports.szcore_inventory:RemoveItem(inv.inventory_id,item,amount) or false
    end

    local wrapper = setmetatable({ Functions = functions, Offline = false }, {
        __index = function(_, key) if key == 'PlayerData' then return qbxData(player) end end
    })
    wrapper._citizenid=player.PlayerData.citizenid
    wrappers[src] = wrapper
    return wrapper
end

local function qbxJobs()
    local source = exports.szcore:GetJobs()
    local out = {}
    for name, job in pairs(source) do
        local grades = {}
        for level, grade in pairs(job.grades) do
            grades[level] = { name = grade.name, isboss = grade.boss == true, payment = grade.salary or 0 }
        end
        out[name] = { label = job.label, type = job.type, defaultDuty = job.defaultDuty == true, offDutyPay = false, grades = grades }
    end
    return out
end

exports('GetPlayer', function(identifier) return wrap(rawPlayer(identifier)) end)
exports('GetPlayerByCitizenId', function(id) return wrap(exports.szcore:GetPlayerByCitizenId(id)) end)
exports('GetPlayersData', function()
    local out = {}
    for _, id in ipairs(GetPlayers()) do local p=rawPlayer(tonumber(id));if p then out[#out+1]=qbxData(p) end end
    return out
end)
exports('GetMoney', function(identifier, account)local p=rawPlayer(identifier);return p and p.getMoney(account) or false end)
exports('AddMoney', function(identifier, account, amount, reason)local p=rawPlayer(identifier);return p and p.addMoney(account, amount, reason) or false end)
exports('RemoveMoney', function(identifier, account, amount, reason)local p=rawPlayer(identifier);return p and p.removeMoney(account, amount, reason) or false end)
exports('SetMoney', function(identifier, account, amount, reason)local p=rawPlayer(identifier);return p and p.setMoney(account, amount, reason) or false end)
exports('SetJob', function(identifier, job, grade)local p=rawPlayer(identifier);return p and exports.szcore:ReplacePrimaryGroup(p.PlayerData.source,'jobs',job,grade) or false end)
exports('SetJobDuty', function(identifier, duty)local p=rawPlayer(identifier);return p and p.setDuty(duty) or false end)
exports('GetMetadata', function(identifier, key)local p=rawPlayer(identifier);return p and p.getMetadata(key) or nil end)
exports('SetMetadata', function(identifier, key, value)local p=rawPlayer(identifier);return p and p.setMetadata(key, value) or false end)
exports('GetDutyCountJob', function(job)local ids=exports.szcore:GetPlayerSourcesByJob(job,true);return #ids,ids end)
exports('GetDutyCountType', function(jobType)
    local count,ids=0,{}
    for _,id in ipairs(GetPlayers()) do local p=rawPlayer(tonumber(id));if p and p.PlayerData.job.type==jobType and p.PlayerData.job.onduty then count=count+1;ids[count]=p.PlayerData.source end end
    return count,ids
end)
exports('GetJobs', qbxJobs)
exports('Save', function(source) return exports.szcore:Save(source, true) end)
exports('Logout', function(source) return exports.szcore:Logout(source, true) end)
exports('GetCoreVersion', function() return 'szcore-compat-1.4.0-rc1' end)

AddEventHandler('szcore:server:playerUnloaded', function(source) wrappers[source] = nil end)
AddEventHandler('szcore:server:jobChanged', function(source)
    local p=rawPlayer(source);if p then TriggerEvent('QBCore:Server:OnJobUpdate',source,qbxJob(p.PlayerData.job)) end
end)
AddEventHandler('szcore:server:dutyChanged', function(source, duty) TriggerEvent('QBCore:Server:SetDuty', source, duty) end)
AddEventHandler('playerDropped',function()wrappers[source]=nil end)

local function resolveCitizen(id) return exports.szcore:GetPlayerByCitizenId(id) end
exports('GetJob',function(name)return qbxJobs()[name]end)
exports('GetGangs',function()return exports.szcore:GetGangs()end)
exports('GetQBPlayers',function()local out={};for _,src in ipairs(exports.szcore:GetPlayerSources())do out[src]=wrap(rawPlayer(src))end;return out end)
exports('AddPlayerToJob',function(cid,name,grade)local p=resolveCitizen(cid);if p then return p.addGroup('jobs',name,grade,false,false)end;return exports.szcore:AddOfflineGroup(cid,'job',name,grade,false,false)end)
exports('AddPlayerToGang',function(cid,name,grade)local p=resolveCitizen(cid);if p then return p.addGroup('gangs',name,grade,false,false)end;return exports.szcore:AddOfflineGroup(cid,'gang',name,grade,false,false)end)
local function removeGroup(cid,kind,name)
    local p=resolveCitizen(cid);local singular=kind=='jobs' and 'job' or 'gang';local fallback=kind=='jobs' and 'unemployed' or 'none'
    if p then
        local current=p.PlayerData[singular]
        if current.name==name then return exports.szcore:ReplacePrimaryGroup(p.PlayerData.source,kind,fallback,0)end
        return p.removeGroup(kind,name)
    end
    local row=exports.szcore:GetOfflinePlayerData(cid);if not row then return false,'player_not_found'end
    if row[singular]==name then
        local ok;if kind=='jobs' then ok=exports.szcore:SetOfflineJob(cid,fallback,0,false)else ok=exports.szcore:SetOfflineGang(cid,fallback,0)end
        if not ok then return false,'database_error'end
    end
    return exports.szcore:RemoveOfflineGroup(cid,singular,name)
end
exports('RemovePlayerFromJob',function(cid,name)return removeGroup(cid,'jobs',name)end)
exports('RemovePlayerFromGang',function(cid,name)return removeGroup(cid,'gangs',name)end)
exports('SetPlayerPrimaryJob',function(cid,name)local p=resolveCitizen(cid);if p then return exports.szcore:SetPrimaryGroup(p.PlayerData.source,'jobs',name)end;return exports.szcore:SetOfflinePrimaryGroup(cid,'job',name)end)
exports('SetPlayerPrimaryGang',function(cid,name)local p=resolveCitizen(cid);if p then return exports.szcore:SetPrimaryGroup(p.PlayerData.source,'gangs',name)end;return exports.szcore:SetOfflinePrimaryGroup(cid,'gang',name)end)
exports('CreateJob',function(name,data)
    local grades={};for k,g in pairs(data.grades or {})do grades[tonumber(k)]={name=g.name,salary=g.payment,boss=g.isboss}end
    return exports.szcore:AddGroupDefinition('job',name,{label=data.label,type=data.type,defaultDuty=data.defaultDuty,grades=grades})
end)
exports('CreateUseableItem',function(name,cb)
    return exports.szcore_inventory:RegisterUsableItem(name,function(src,e,slot)cb(src,{name=e.name,amount=e.amount,info=e.metadata,slot=slot})end)
end)
