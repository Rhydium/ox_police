Config = {}

Config.PoliceGroups = {
    -- data: object, name: string, label: string, grades: object[] label: string accountRole?: string, type?: string, colour?: number, hasAccount?: boolean
    {
        name = 'police',
        label = 'Police',
        grades = {
            { label = 'Cadet' },
            { label = 'Officer' },
            { label = 'Sergeant' },
            { label = 'Lieutenant' },
            { label = 'Captain' },
            { label = 'Chief' },
        },
        type = 'job',
    },
}
