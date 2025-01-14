RegisterServerEvent('ox_police:impoundVehicle', function(netid)
  local vehicle = NetworkGetEntityFromNetworkId(netid)
  DeleteEntity(vehicle)
end)
