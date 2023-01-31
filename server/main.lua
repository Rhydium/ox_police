local players = {}
local table = lib.table
local glm = require 'glm'

CreateThread(function()
    for _, player in pairs(Ox.GetPlayers(true, { groups = Config.PoliceGroups })) do
        local inService = player.get('inService')

        if inService and table.contains(Config.PoliceGroups, inService) then
            players[player.source] = player
        end
    end
end)

RegisterNetEvent('ox:setPlayerInService', function(group)
    local player = Ox.GetPlayer(source)

    if player then
        if group and table.contains(Config.PoliceGroups, group) and player.hasGroup(Config.PoliceGroups) then
            players[source] = player
            return player.set('inService', group, true)
        end

        player.set('inService', false, true)
    end

    players[source] = nil
end)

AddEventHandler('ox:playerLogout', function(source)
    players[source] = nil
end)

lib.callback.register('ox_police:isPlayerInService', function(source, target)
    return players[target or source]
end)

lib.callback.register('ox_police:setPlayerCuffs', function(source, target)
    local player = Ox.GetPlayer(source)

    if not player then return end

    target = Player(target)?.state

    if not target then return end

    local state = not target.isCuffed

    target:set('isCuffed', state, true)

    return state
end)

RegisterNetEvent('ox_police:setPlayerEscort', function(target, state)
    local player = Ox.GetPlayer(source)

    if not player then return end

    target = Player(target)?.state

    if not target then return end

    target:set('isEscorted', state and source, true)
end)

AddEventHandler('ox:playerLoaded', function(source, userid, charid)
    local playerId = Ox.GetPlayer(source)
	MySQL.query('SELECT sentence FROM characters WHERE charid = @charid', {
		['@charid'] = charid,
	}, function (result)
		local remaining = result[1].sentence
        Player(source).state:set('sentence', remaining, true)
        TriggerEvent('server:beginSentence', playerId.source , remaining, true )
	end)

end)

---@param id string
---@param sentence string
---@param resume boolean
RegisterServerEvent('server:beginSentence',function(id, sentence, resume)
    if sentence == 0 then return end
    local playerId = Ox.GetPlayer(id)

	MySQL.update.await('UPDATE characters SET sentence = @sentence WHERE charid = @charid', {
		['@sentence'] = sentence,
		['@charid']   = playerId.charid,
	}, function(rowsChanged)
	end)

    TriggerClientEvent('ox_lib:notify', id, {
        title = 'Jailed',
        description = 'You have been sentenced to ' .. sentence .. ' minutes.',
        type = 'inform'
    })
    if not resume then
        exports.ox_inventory:ConfiscateInventory(id)
    end

	TriggerClientEvent('sendToJail', id, sentence)
end)

---@param target string
---@param sentence string
RegisterServerEvent('updateSentence',function(sentence, target)
    local playerId = Ox.GetPlayer(target)

	MySQL.update.await('UPDATE characters SET sentence = @sentence WHERE charid = @charid', {
		['@sentence'] = sentence,
		['@charid']   = playerId.charid,
	}, function(rowsChanged)
        Player(source).state:set('sentence', sentence, true)
	end)

	if sentence <= 0 then
		if target ~= nil then
            SetEntityCoords(target, Config.unJailCoords.x, Config.unJailCoords.y, Config.unJailCoords.z)
            SetEntityHeading( target, Config.unJailHeading)
            exports.ox_inventory:ReturnInventory(target)
            TriggerClientEvent('ox_lib:notify', target, {
                title = 'Jail',
                description = 'Your sentence has ended.',
                type = 'inform'
            })
		end
	end
end)

---@param fine string
---@param id string
---@param message string
RegisterServerEvent("confirmation",function(fine, id, message)
    local target = id
    TriggerClientEvent("sendConfirm", id, fine, src, message)
end)

---@param officer string
RegisterServerEvent("refusedFine", function(officer)
    local src = source
    TriggerClientEvent('ox_lib:notify', officer, {
        type = 'error',
        description = 'Fine has been refused.',
    })
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'error',
        description = 'You have refused the fine.',
    })
end)

---@param fine string
---@param officer string
---@param message string
RegisterServerEvent("acceptedFine", function(fine, officer, message)
    local src = source
    local officerName = Ox.GetPlayer(officer)
    local playerName = Ox.GetPlayer(src)
    exports.pefcl:createInvoice(src, {from = officerName.name, toIdentifier = src, to = playerName.name, fromIdentifier = officer, amount = fine, message = message, src,})
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Fine Accepted',
    })
    TriggerClientEvent('ox_lib:notify', officer, {
        type = 'success',
        description = 'Fine Accepted',
    })
end)

RegisterNetEvent('gsrTest', function(target)
	local src = source
	local ply = Player(target)
	if ply.state.shot == true then
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = 'Test comes back POSITIVE (Has Shot)'})
	else
        TriggerClientEvent('ox_lib:notify', src, {type = 'error', description = 'Test comes back NEGATIVE (Has Not Shot)'})
	end
end)

local evidence = {}
local addEvidence = {}
local clearEvidence = {}

CreateThread(function()
    while true do
        Wait(1000)

        if next(addEvidence) or next(clearEvidence) then
            TriggerClientEvent('ox_police:updateEvidence', -1, addEvidence, clearEvidence)

            table.wipe(addEvidence)
            table.wipe(clearEvidence)
        end
    end
end)

RegisterServerEvent('ox_police:distributeEvidence', function(nodes)
    for coords, items in pairs(nodes) do
        if evidence[coords] then
            lib.table.merge(evidence[coords], items)
        else
            evidence[coords] = items
            addEvidence[coords] = true
        end
    end
end)

RegisterServerEvent('ox_police:collectEvidence', function(nodes)
    local items = {}

    for i = 1, #nodes do
        local coords = nodes[i]

        lib.table.merge(items, evidence[coords])

        clearEvidence[coords] = true
        evidence[coords] = nil
    end

    for item, data in pairs(items) do
        for type, count in pairs(data) do
            exports.ox_inventory:AddItem(source, item, count, type)
        end
    end

    lib.notify(source, {type = 'success', title = 'Evidence collected'})
end)

RegisterServerEvent('ox_police:deploySpikestrip', function(data)
    local count = exports.ox_inventory:Search(source, 'count', 'spikestrip')

    if count < data.size then return end

    exports.ox_inventory:RemoveItem(source, 'spikestrip', data.size)

    local dir = glm.direction(data.segment[1], data.segment[2])

    for i = 1, data.size do
        local coords = glm.segment.getPoint(data.segment[1], data.segment[2], (i * 2 - 1) / (data.size * 2))
        local object = CreateObject(`p_ld_stinger_s`, coords.x, coords.y, coords.z, true, true, true)

        while not DoesEntityExist(object) do
            Wait(0)
        end

        SetEntityRotation(object, math.deg(-math.sin(dir.z)), 0.0, math.deg(math.atan(dir.y, dir.x)) + 90, 2, false)
        Entity(object).state:set('inScope', true, true)
    end
end)

RegisterServerEvent('ox_police:retrieveSpikestrip', function(netId)
    local ped = GetPlayerPed(source)

    if GetVehiclePedIsIn(ped, false) ~= 0 then return end

    local pedPos = GetEntityCoords(ped)
    local spike = NetworkGetEntityFromNetworkId(netId)
    local spikePos = GetEntityCoords(spike)

    if #(pedPos - spikePos) > 5 then return end

    if not exports.ox_inventory:CanCarryItem(source, 'spikestrip', 1) then return end

    DeleteEntity(spike)

    exports.ox_inventory:AddItem(source, 'spikestrip', 1)
end)
