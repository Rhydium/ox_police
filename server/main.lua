local players = {}
local glm = require 'glm'

CreateThread(function()
    for _, player in pairs(Ox.GetPlayers()) do
        local inService = player.get('inService')

        if inService and player.getGroup(inService) then
            players[player.source] = player
        end
    end
end)

RegisterServerEvent('ox:setPlayerInService', function(group)
    local player = Ox.GetPlayer(source)

    if player then
        if group and player.getGroup(group) then
            players[source] = player
            return player.set('inService', group, true)
        end

        player.set('inService', false, true)
    end

    players[source] = nil
end)

AddEventHandler('onResourceStart', function()
    Wait(1000)

    -- Check if group exists in the database and if not, create it using Ox.CreateGroup(data)
    for _, group in ipairs(Config.PoliceGroups) do
        if not Ox.GetGroup(group.name) then
            Ox.CreateGroup(group)
        end
    end

    -- Set the group permissions for the police groups
    -- Ox.SetGroupPermissions(groupName, grade, permission, value)
    for _, group in ipairs(Config.PoliceGroups) do
        local groupName = group.name

        -- Check if the group has grades defined
        if group.grades then
            for gradeIndex, grade in ipairs(group.grades) do
                -- Check if the grade has specific permissions
                if grade.permissions then
                    for _, permission in ipairs(grade.permissions) do
                        local permissionName = permission.permission
                        local permissionValue = permission.value

                        -- Set the permission for the group and grade
                        Ox.SetGroupPermission(groupName, gradeIndex, permissionName, permissionValue)
                        print(string.format("Permission set: %s, Grade: %d, Permission: %s, Value: %s",
                            groupName, gradeIndex, permissionName, permissionValue))
                    end
                end
            end
        end
    end
end)

AddEventHandler('ox:playerLogout', function(source)
    players[source] = nil
end)

lib.callback.register('ox_police:isPlayerInService', function(source, target)
    return players[target or source]
end)

function IsPlayerInService(source)
    return players[source]
end

lib.callback.register('ox_police:setPlayerCuffs', function(source, target)
    local player = Ox.GetPlayer(source)

    if not player then return end

    target = Player(target)?.state

    if not target then return end

    local state = not target.isCuffed

    target:set('isCuffed', state, true)

    return state
end)

RegisterServerEvent('ox_police:setPlayerEscort', function(target, state)
    local player = Ox.GetPlayer(source)

    if not player then return end

    target = Player(target)?.state

    if not target then return end

    target:set('isEscorted', state and source, true)
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

        table.merge(items, evidence[coords])

        clearEvidence[coords] = true
        evidence[coords] = nil
    end

    for item, data in pairs(items) do
        for type, count in pairs(data) do
            exports.ox_inventory:AddItem(source, item, count, type)
        end
    end

    lib.notify(source, { type = 'success', title = 'Evidence collected' })
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
