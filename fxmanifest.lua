fx_version "cerulean"
game "gta5"
lua54 "yes"

author "ked.ss"
description "Park Meter"
version "1.0.0"

shared_scripts {
    "@ox_lib/init.lua",
    "Config.lua",
    "locales/*.lua",
    "shared/server.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/**.lua"
}

client_scripts {
    "client/**.lua",
    "shared/client.lua"
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style/styles.css',
    'html/style/purchase.css',
    'html/style/script.js'
}