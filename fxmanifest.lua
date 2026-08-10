fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Gatrons Development'

ui_page 'ui/dist/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/shop_config.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/main.lua',
    'client/shop.lua',
    'client/nui.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/integrations/inventory.lua',
    'server/integrations/framework.lua',
    'server/integrations/garage.lua',
    'server/coin.lua',
    'server/admin.lua',
    'server/shop.lua',
    'server/gacha.lua',
    'server/storage.lua',
    'server/main.lua',
}

files {
    'ui/dist/index.html',
    'ui/dist/**/*',
}
