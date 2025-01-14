-- Only register the radial menu if the player is a police officer and is in service
local registeredRadial = false

CreateThread(function()
  while true do
    Wait(1000)
    if InService and not registeredRadial then
      lib.registerRadial({
        id = 'police_menu',
        items = {
          {
            label = 'Handcuff',
            icon = 'handcuffs',
            onSelect = 'myMenuHandler'
          },
          {
            label = 'Frisk',
            icon = 'hand'
          },
          {
            label = 'Fingerprint',
            icon = 'fingerprint'
          },
          {
            label = 'Jail',
            icon = 'bus'
          },
          {
            label = 'Search',
            icon = 'magnifying-glass',
            onSelect = function()
              print('Search')
            end
          }
        }
      })

      lib.addRadialItem({
        id = 'police',
        label = 'Police',
        icon = 'shield-halved',
        menu = 'police_menu'
      })

      registeredRadial = true
    else
      if not InService and registeredRadial then
        lib.removeRadialItem('police')
        registeredRadial = false
      end
    end
  end
end)
