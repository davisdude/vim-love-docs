local api = require 'love-api.love_api'

local originalfuncstr = 'syntax match lovefunction "\\<love\\.\\('
local funcstr = originalfuncstr

local originaltypestr = 'syntax match lovetype "[\\:\\.]\\('
local typestr = originaltypestr

local originalcallbackstr = originalfuncstr
local callbackstr = originalcallbackstr

local originalconfstr = 'syntax match loveconf "'
local confstr = originalconfstr

print( 'syn region lovefuncregion transparent start=\'love.conf\' end=\'end\' contains=ALL' )

local function extractData( tab, index )
	for i, v in pairs( tab ) do
		if i == 'functions' or i == 'callbacks' or i == 'config' then
			if tab.name and ( tab.name or '' ):sub( 1, 1 ):match( '%l' ) then funcstr = funcstr .. tab.name .. '\\.\\(' end
			local func = false
			local typ = false
			local callback = false
			if i == 'config' then
				print( 'syntax match loveconf "\\(\\<love\\.conf\\>\\)"' )
				for _, vv in pairs( v ) do
					if vv.name then
						confstr = confstr .. '\\(\\.'
						if type( vv ) == 'table' then
							confstr = confstr .. vv.name .. '\\('
							local hasSubs = false
							for _, vvv in pairs( vv.table or {} ) do
								hasSubs = true
								confstr = confstr .. '\\.' .. vvv.name .. '\\|'
							end
							if hasSubs then confstr = confstr:sub( 1, -3 ) .. '\\)'
							else confstr = confstr:sub( 1, -3 ) end
							confstr = confstr .. '\\>'
						end
						confstr = confstr:sub( 1, -1 ) .. '\\)\\|'
					end
				end
				print( confstr:sub( 1, -3 ) .. '"ms=s+1 contained' )
			else
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
					-- We don't want to be able to have underscores after the word
					callbackstr = callbackstr:sub( 1, -3 ) .. '\\)\\>"'
					print( callbackstr )
					callbackstr = originalcallbackstr
				end
			end
		end
		if type( v ) == 'table' then extractData( v ) end
	end
end
extractData( api )

print( 'highlight lovefunction guifg=#ff60e2' )
print( 'highlight lovetype guifg=#ff60e2' )
print( 'highlight loveconf guifg=#ff60e2' )

love.event.quit()
