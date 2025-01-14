player = Ox.GetPlayer()

local PoliceGroupNames = {}
for _, group in ipairs(Config.PoliceGroups) do
    table.insert(PoliceGroupNames, group.name)
end

InService = player and player.inService and table.contains(PoliceGroupNames, player.inService) and
    player.getGroup(PoliceGroupNames) ~= nil

RegisterCommand('duty', function()
    local wasInService = InService
    local group = player.getGroup(PoliceGroupNames)
    InService = not InService and group ~= nil or false

    if not wasInService and not InService then
        lib.notify({
            description = 'Service not available',
            type = 'error'
        })
    else
        TriggerServerEvent('ox:setPlayerInService', InService and group or false)
        lib.notify({
            description = InService and 'In Service' or 'Out of Service',
            type = 'success'
        })
    end
end)

RegisterCommand('checkifinduty', function()
    if InService then
        lib.notify({
            description = 'You are in service',
            type = 'success'
        })
    else
        lib.notify({
            description = 'You are not in service',
            type = 'error'
        })
    end
end)

AddEventHandler('ox:playerLogout', function()
    InService = false
    LocalPlayer.state:set('isCuffed', false, true)
    LocalPlayer.state:set('isEscorted', false, true)
end)
