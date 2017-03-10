-- Generate syntax matching for love.conf
-- TODO:
-- 		- 	Allow support for variant love.conf = function()
--			(may not work because lua function overrides?)
package.path = package.path .. ';../love-api/love_api.lua;love-api/?.lua'
local api = require 'love-api/love_api'

local originalconfstr = 'syntax match loveconf "'
local confstr = originalconfstr

local function extractData( tab, index )
	for i, v in pairs( tab ) do
		if i == 'functions' or i == 'callbacks' then
			if tab.name and ( tab.name or '' ):sub( 1, 1 ):match( '%l' ) then funcstr = funcstr .. tab.name .. '\\.\\%(' end
			local func = false
			local typ = false
			local callback = false
			for _, vv in pairs( v ) do
				if vv.name == 'conf' then
					for _, vvv in pairs( vv.variants[1].arguments[1].table ) do
						if vvv.name then
							confstr = confstr .. '\\%(\\.'
							if type( vvv ) == 'table' then
								confstr = confstr .. vvv.name .. '\\%('
								local hasSubs = false
								for _, vvvv in pairs( vvv.table or {} ) do
									hasSubs = true
									confstr = confstr .. '\\.' .. vvvv.name .. '\\|'
								end
								if hasSubs then confstr = confstr:sub( 1, -3 ) .. '\\)'
								else confstr = confstr:sub( 1, -4 ) end
								confstr = confstr .. '\\>'
							end
							confstr = confstr:sub( 1, -1 ) .. '\\)\\|'
						end
					end
					print( confstr:sub( 1, -3 ) .. '"ms=s+1 containedin=loveconfregion' )
				end
			end
			if type( v ) == 'table' then extractData( v ) end
		end
	end
end

extractData( api )
love.event.quit()
