fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependencies {
    '/server:7290',
    '/onesync',
    'ox_core',
    'ox_lib',
    'oxmysql',
}

shared_scripts {
    '@ox_core/lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/garage.lua',
    'server/impound.lua',
}

client_scripts {
    'client/main.lua',
    'client/cuff.lua',
    'client/escort.lua',
    'client/spikes.lua',
    'client/evidence.lua',
    'client/radialmenu.lua',
    'client/impound.lua',
    'client/garage.lua',
    'client/utils.lua',
}

files {
    'data/*.lua',
    'locales/*.json',
    'client/utils.lua',
}

ox_libs {
    'table',
    'locale',
}
