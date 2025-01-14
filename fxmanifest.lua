fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
    '@ox_core/lib/init.lua',
    'config.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/cuff.lua',
    'client/escort.lua',
    'client/spikes.lua',
    'client/evidence.lua',
    'client/radialmenu.lua',
    'client/impound.lua',
}

files {
    'data/**.lua'
}

ox_libs {
    'table'
}
