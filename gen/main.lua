local api = require 'love-api.love_api'

print( [[if exists( "b:love_syntax" )
	finish
endif]] )
print( 'let b:love_syntax = 1' )

local originalfuncstr = 'syntax match lovefunction "\\<love\\.\\('
local funcstr = originalfuncstr

local originaltypestr = 'syntax match lovetype "[\\:\\.]\\('
local typestr = originaltypestr

local originalcallbackstr = originalfuncstr
local callbackstr = originalcallbackstr

local function extractData( tab, index )
	for i, v in pairs( tab ) do
		if i == 'functions' or i == 'callbacks' then
			if tab.name and ( tab.name or '' ):sub( 1, 1 ):match( '%l' ) then funcstr = funcstr .. tab.name .. '\\.\\(' end
			local func = false
			local typ = false
			local callback = false
			for _, vv in pairs( v ) do
				if tab.name then
					if tab.name:sub( 1, 1 ):match( '%l' ) then
						func = true
						funcstr = funcstr .. vv.name .. '\\|'
					else -- types
						typ = true
						typestr = typestr .. vv.name .. '\\|'
					end
				else
					callback = true
					callbackstr = callbackstr .. vv.name .. '\\|'
				end
			end
			if func then 
				funcstr = funcstr:sub( 1, -3 ) .. '\\)\\)\\>"'
				print( funcstr )
				funcstr = originalfuncstr
			end
			if typ then
				-- We don't want to be able to have underscores after the word or highlight the . or :
				typestr = typestr:sub( 1, -3 ) .. '\\)\\_[^_a-zA-Z]"ms=s+1,me=e-1'
				print( typestr )
				typestr = originaltypestr
			end
			if callback then 
				callbackstr = callbackstr:sub( 1, -3 ) .. '\\)\\>"'
				print( callbackstr )
				callbackstr = originalcallbackstr
			end
		end
		if type( v ) == 'table' then extractData( v ) end
	end
end
extractData( api )

print( 'let b:current_syntax = "lua"' )
print( 'highlight lovefunction guifg=#ff60e2' )
print( 'highlight lovetype guifg=#ff60e2' )

love.event.quit()
