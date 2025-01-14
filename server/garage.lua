local garages = require 'data.garages'

local function checkPlayerIsInPoliceGroups(player)
  -- We want to check if the player is in any of the police groups defined in the config.lua
  for _, group in ipairs(Config.PoliceGroups) do
    if player.getGroup(group.name) then
      return true
    end
  end
end

local function getPlayerGroupGrade(player)
  -- We want to check what grade the player is in the police group
  -- Unfortunately we can only retrieve this by checking all groups with the type 'job' by using player.getGroupByType('job')
  -- and then checking if the group is a police group
  local groups = player.getGroupByType('job')
  for _, group in ipairs(groups) do
    if checkPlayerIsInPoliceGroups(group) then
      print('group:', group.getGrade())
      return group.getGrade()
    end
  end
end

local function checkPlayerIsInService(player)
  -- We want to check if the player is in service for any of the police groups
  for _, group in ipairs(Config.PoliceGroups) do
    if player.get('inService', group.name) then
      return true
    end
  end

  return false
end

lib.callback.register('ox_police:getAvailableVehicles', function(source)
  local player = Ox.GetPlayer(source)

  if not player then
    return false, 'wrong_args'
  end
  print('passed player check')

  if not checkPlayerIsInPoliceGroups(player) and not checkPlayerIsInService(player) then
    return false, 'no_permission'
  end
  print('passed duty and group check')

  local vehicles = {}
  print('starting for loop')
  for _, vehicle in ipairs(Config.PoliceVehicles) do
    print('Permission:', vehicle.requiredPermission)
    print('Does player have perm?:', player.hasPermission(vehicle.requiredPermission))
    if player.hasPermission(vehicle.requiredPermission) then
      print('Permission:', vehicle.requiredPermission)
      print('Does player have perm?:', player.hasPermission(vehicle.requiredPermission))
      table.insert(vehicles, { model = vehicle.model })
    end
  end

  print('vehicles:', json.encode(vehicles))
  return true, vehicles
end)

lib.callback.register('ox_police:spawnVehicle', function(source, data)
  print('spawnVehicle called with data:', json.encode(data))

  local player = Ox.GetPlayer(source)
  local garage = garages[data.garageId]
  local spawnCoords = garage and garage.spots and garage.spots[data.spawnIndex]

  -- Validate input and ensure all required data exists
  if not player then
    return false, 'player_not_found'
  end

  if not garage then
    return false, 'garage_not_found'
  end

  if not spawnCoords then
    return false, 'invalid_spawn_coords'
  end

  -- Check if the player has permission for the requested vehicle
  local requiredPermission = 'group.police.vehicle.' .. (data.model or 'unknown')
  if not player.hasPermission(requiredPermission) then
    return false, 'no_permission'
  end

  -- Spawn the vehicle (Assume model is already validated on the client)
  local vehicle = CreateVehicleServerSetter(
    GetHashKey(data.model),
    'automobile',
    spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w
  )

  if not DoesEntityExist(vehicle) then
    print('Failed to spawn vehicle:', data.model)
    return false, 'spawn_error'
  end

  print(('Vehicle %s spawned for player %s at %s'):format(data.model, player.identifier, json.encode(spawnCoords)))

  return true
end)


lib.callback.register('ox_police:storeVehicle', function(source, netId)
  local player = Ox.GetPlayer(source)
  local vehicle = NetworkGetEntityFromNetworkId(netId)

  -- Check if the player and vehicle exist and if the player is a police officer
  if not player or not vehicle then return false, 'wrong_args' end
  if not checkPlayerIsInPoliceGroups(player) and not checkPlayerIsInService(player) then return false, 'no_permission' end

  -- Check if the vehicle is a police vehicle
  local vehicleModel = GetEntityModel(vehicle)
  local isPoliceVehicle = false

  for _, policeVehicle in ipairs(Config.PoliceVehicles) do
    if GetHashKey(policeVehicle.model) == vehicleModel then
      isPoliceVehicle = true
      break
    end
  end

  if not isPoliceVehicle then return false, 'invalid_vehicle' end

  -- We can just delete the vehicle here, as it's not being stored in a garage
  return true, DeleteEntity(vehicle)
end)
