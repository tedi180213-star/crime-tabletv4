fx_version 'cerulean'
game 'gta5'

author 'Tedi'
description 'Crime Tablet - Boosting, Heist & Black Market'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/img/*.png'
}

lua54 'yes'

dependencies {
    'es_extended',
    'oxmysql',
    'ox_inventory'
}
