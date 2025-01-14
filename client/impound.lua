local function impoundVehicle(entity)
  local input = lib.inputDialog('Impound Vehicle', {
    { type = 'input',  label = 'Reason',          description = 'Set a reason for impounding the vehicle',         required = true },
    { type = 'number', label = 'Fine',            description = 'Set a fine for impounding the vehicle',           icon = 'dollar-sign',         required = true },
    { type = 'date',   label = 'Impounded Until', description = 'Set a date for when the vehicle can be released', icon = { 'far', 'calendar' }, default = 1,    format = "DD/MM/YYYY", required = true }
  })
  print(json.encode(input))

  local vehicle = NetworkGetNetworkIdFromEntity(entity)
  TriggerServerEvent('ox_police:impoundVehicle', vehicle)
end

exports.ox_target:addGlobalVehicle(
  {
    name = 'impound',
    icon = 'fas fa-car-crash',
    label = 'Impound',
    distance = 5.0,
    canInteract = function(entity)
      return IsEntityAVehicle(entity) and not IsPedInAnyVehicle(PlayerPedId(), false) and
          GetPedInVehicleSeat(entity, -1) == 0 and InService
    end,
    onSelect = function(data)
      impoundVehicle(data.entity)
    end
  }
)
