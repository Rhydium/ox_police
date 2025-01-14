Config = {}

Config.PoliceGroups = {
    {
        name = 'police',
        label = 'Police',
        grades = {
            {
                label = 'Cadet',
                permissions = {
                    { groupName = 'police', grade = 1, permission = 'vehicle.police', value = 'allow' }
                }
            },
            { label = 'Officer' },
            { label = 'Sergeant' },
            { label = 'Lieutenant' },
            { label = 'Captain' },
            { label = 'Chief' },
        },
        type = 'job',
    },
}

Config.PoliceVehicles = {
    {
        model = 'police',
        label = 'Police Cruiser',
        requiredPermission = 'group.police.vehicle.police'
    },
    {
        model = 'police2',
        label = 'Police Buffalo',
        requiredPermission = 'group.police.vehicle.police2'
    },
    {
        model = 'police3',
        label = 'Police Interceptor',
        requiredPermission = 'group.police.vehicle.police3'
    }
}
