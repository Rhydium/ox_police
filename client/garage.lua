local garages = require 'data.garages'
local utils = require 'client.utils'
local player = Ox.GetPlayer()
local inZone = nil

local function hasPermission(garage)
  if garage.group then
    return player.getGroup(garage.group)
  end

  return true
end

local function updateTextUI(vehicle)
  local garage = garages[inZone]

  if vehicle and garage.type ~= 'impound' then
    lib.showTextUI(
      ('**%s**  \n%s [%s]'):format(locale('store_vehicle'), locale('interact_with'),
        utils.getKeyNameForCommand(`+ox_lib-radial`)), {
        icon = 'fa-square-parking'
      })
  else
    lib.showTextUI(
      ('**%s**  \n%s [%s]'):format(locale('retrieve_vehicle'), locale('interact_with'),
        utils.getKeyNameForCommand(`+ox_lib-radial`)), {
        icon = 'fa-square-parking'
      })
  end
end

local function onEnter(zone)
  inZone = zone.zoneId

  if not hasPermission(zone) then return end

  updateTextUI(cache.vehicle)
  lib.addRadialItem({
    id = 'garage_item',
    icon = 'square-parking',
    label = locale('garage_label'),
    onSelect = function()
      local garage = garages[inZone]

      if cache.vehicle and garage.type ~= 'impound' then
        StoreVehicle(cache.vehicle, inZone)
      else
        OpenRetrieveMenu(inZone)
      end
    end
  })
end

local function onExit(zone)
  inZone = nil

  if not hasPermission(zone) then return end

  lib.hideTextUI()
  lib.removeRadialItem('garage_item')
end

for i, v in pairs(garages) do
  lib.zones.poly({
    points = v.zone.points,
    thickness = v.zone.thickness,
    debug = false,
    zoneId = i,
    group = v.group,
    onEnter = onEnter,
    onExit = onExit
  })
end

lib.onCache('vehicle', function(vehicle)
  if not inZone then return end

  local garage = garages[inZone]
  if not hasPermission(garage) then return end

  if vehicle then
    -- Player is in a vehicle; update UI for storing
    lib.showTextUI(
      ('**%s**  \n%s [%s]'):format(locale('store_vehicle'), locale('interact_with'),
        utils.getKeyNameForCommand(`+ox_lib-radial`)), {
        icon = 'fa-square-parking'
      }
    )
    lib.addRadialItem({
      id = 'store_vehicle_item',
      icon = 'car',
      label = locale('store_vehicle'),
      onSelect = function()
        StoreVehicle(vehicle, inZone)
      end
    })
  else
    -- Player is not in a vehicle; update UI for retrieving
    updateTextUI(vehicle)
    lib.removeRadialItem('store_vehicle_item') -- Ensure the store item is removed when not needed
  end
end)

function StoreVehicle(vehicle, garageId)
  -- Retrieve the vehicle's network ID
  local netId = NetworkGetNetworkIdFromEntity(vehicle)

  -- Call the server-side callback to store the vehicle
  local success, error = lib.callback.await('ox_police:storeVehicle', 5000, netId)

  if success then
    lib.notify({
      id = 'garage_store_success',
      title = "Garage",
      description = "Your vehicle has been stored.",
      type = 'success'
    })

    -- Delete the vehicle locally
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
  else
    lib.notify({
      id = 'garage_store_error',
      title = "Garage",
      description = locale(error) or "There was an issue storing your vehicle.",
      type = 'error'
    })
  end
end

function RetrieveVehicle(data)
  local garage = garages[data.garageId]

  -- Find the closest vacant parking spot
  local spawnIndex = utils.getClosestVacantCoord(garage.spots)
  if not spawnIndex then
    return lib.notify({
      id = 'garage_retrieve_error',
      title = 'Garage',
      description = 'There are no available parking spots.',
      type = 'error'
    })
  end

  -- Validate the vehicle model on the client side
  local modelHash = GetHashKey(data.model)
  if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
    return lib.notify({
      id = 'garage_retrieve_error',
      title = 'Garage',
      description = 'Invalid vehicle model.',
      type = 'error'
    })
  end

  -- Call the server-side callback to spawn the vehicle
  local success, error = lib.callback.await('ox_police:spawnVehicle', 5000, {
    model = data.model,         -- Vehicle model to spawn
    garageId = data.garageId,   -- Garage ID
    spawnIndex = spawnIndex     -- Parking spot index
  })

  if success then
    lib.notify({
      id = 'garage_retrieve_success',
      title = "Garage",
      description = "Your vehicle has been retrieved.",
      type = 'success'
    })
  else
    lib.notify({
      id = 'garage_retrieve_error',
      title = "Garage",
      description = locale(error) or "Please wait a few seconds before trying that again.",
      type = 'error'
    })
  end
end

local function generateOptions(vehicles, garageId)
  local options = {}

  for i = 1, #vehicles do
    local vehicle = vehicles[i]
    local vehicleData = Ox.GetVehicleData(vehicle.model) -- Fetch vehicle data based on the model

    if vehicleData then
      options[#options + 1] = {
        title = utils.getVehicleFullName(vehicleData.name, vehicleData.make),
        description = locale("Model: %s", vehicle.label or vehicle.model), -- Fallback to model if label is missing
        icon = ('https://docs.fivem.net/vehicles/%s.webp'):format(vehicle.model),
        onSelect = RetrieveVehicle,
        args = {
          model = vehicle.model, -- Include the model in args
          garageId = garageId    -- Pass the garage ID
        },
        arrow = true,
        metadata = {
          {
            label = "Doors",
            value = vehicleData.doors or "N/A"
          },
          {
            label = "Seats",
            value = vehicleData.seats or "N/A"
          }
        }
      }
    else
      print(('Vehicle data not found for model: %s'):format(vehicle.model))
    end
  end

  return options
end

function OpenRetrieveMenu(garageId)
  local garage = garages[garageId]
  local params = { owner = true }

  -- Await callback response
  local success, data = lib.callback.await('ox_police:getAvailableVehicles', 2000)

  if not success then
    -- Handle callback failure
    lib.notify({
      id = 'garage_retrieve_error',
      title = "Garage",
      description = locale(data) or "Please wait a few seconds before trying that again.",
      type = 'error'
    })
    return
  end

  -- Debug callback data
  print('Callback success:', success)
  print('Callback data:', json.encode(data))

  -- Ensure `data` is valid
  if not data or type(data) ~= 'table' or next(data) == nil then
    lib.notify({
      id = 'garage_retrieve_info',
      title = "Garage",
      description = "There are no owned vehicles in this garage.",
      type = 'info'
    })
    return
  end

  -- Generate menu options and show the context menu
  lib.registerContext({
    id = 'garage_menu',
    title = garage.label,
    options = generateOptions(data, garageId),
    menu = garage.group and 'garage_type'
  })
  lib.showContext('garage_menu')
end
