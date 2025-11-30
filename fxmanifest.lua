fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'ox_fuel'
author 'Overextended'
version '1.5.1'
repository 'https://github.com/overextended/ox_fuel'
description 'Fuel management system with ox_inventory support and modern NUI'

dependencies {
	'ox_lib',
	'ox_inventory',
}

ui_page 'web/index.html'

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'bridge/framework.lua'
}

server_scripts {
	'bridge/server.lua',
	'server.lua'
}

client_script 'client/init.lua'

files {
	'web/index.html',
	'web/style.css',
	'web/script.js',
	'locales/*.json',
	'data/stations.lua',
	'client/*.lua',
	'bridge/*.lua',
	'bridge/qbox/*.lua',
}

ox_libs {
	'math',
	'locale',
}
