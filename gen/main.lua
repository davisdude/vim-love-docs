local api = require 'love-api.love_api'

local oldprint = print
local function print( group, str, contained )
	oldprint( 'syntax match ' .. group .. ' ' .. '"' .. str:gsub( '[%.:]', '\\%1' ) .. '"' .. ( contained or '' ) )
end


oldprint( [[if exists( "b:love_syntax" )
	finish
endif]] )
oldprint( 'let b:love_syntax = 1' )

local originalfuncstr = 'syntax match lovefunction "\\(^\\|\\s\\)love\\.\\('
local funcstr = originalfuncstr

local originaltypestr = 'syntax match lovetype "[\\:\\.]\\('
local typestr = originaltypestr

local originalcallbackstr = 'syntax match lovefunction "\\(^\\|\\s\\)love\\.\\('
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
				-- We don't want to be able to have underscores after the word
				funcstr = funcstr:sub( 1, -3 ) .. '\\)\\)\\_[^_a-zA-Z]"me=e-1'
				oldprint( funcstr )
				funcstr = originalfuncstr
			end
			if typ then
				-- We don't want to be able to have underscores after the word or highlight the . or :
				typestr = typestr:sub( 1, -3 ) .. '\\)\\_[^_a-zA-Z]"ms=s+1,me=e-1'
				oldprint( typestr )
				typestr = originaltypestr
			end
			if callback then 
				-- We don't want to be able to have underscores after the word
				callbackstr = callbackstr:sub( 1, -3 ) .. '\\)\\_[^_a-zA-Z]"me=e-1'
				oldprint( callbackstr )
				callbackstr = originalcallbackstr
			end
		end
		if type( v ) == 'table' then extractData( v ) end
	end
end
extractData( api )

oldprint( 'let b:current_syntax = "lua"' )
oldprint( 'highlight lovefunction guifg=#ff60e2' )
oldprint( 'highlight lovetype guifg=#ff60e2' )

love.event.quit()
