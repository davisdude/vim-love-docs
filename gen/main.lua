local api = require 'love-api.love_api'

local oldprint = print
local function print( group, str, contained )
	oldprint( 'syntax match ' .. group .. ' ' .. '"' .. str:gsub( '[%.:]', '\\%1' ) .. '" ' .. ( contained or '' ) )
end

oldprint( 'syntax match lovepunctuation "[\\:\\.]" nextgroup=lovetype' )
local function extractData( tab, index )
	for i, v in pairs( tab ) do
		if i == 'functions' or i == 'callbacks' then
			for _, vv in pairs( v ) do
				if tab.name then
					if tab.name:sub( 1, 1 ):match( '%l' ) then
						print( 'lovefunction', 'love.' .. tab.name .. '.' .. vv.name )
					else -- types
						print( 'lovetype', vv.name, 'contained' )
					end
				else
					print( 'lovefunction', 'love.' .. vv.name )
				end
			end
		end
		if type( v ) == 'table' then extractData( v ) end
	end
end
extractData( api )
oldprint( 'highlight lovefunction guifg=#ff60e2' )
oldprint( 'highlight lovetype guifg=#ff60e2' )
oldprint( 'highlight lovepunctuation NONE' )

love.event.quit()
