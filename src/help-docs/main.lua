local api = require 'love-api.love_api'

local bodies = {}
local enums = {}
local maxWidth = 78
local contentWidth = 46
local index = '0.'
local docName = 'love-'

local function increment()
	index = index:gsub( '(.-)(%d+)%.$', function( a, b ) return a .. ( b + 1 ) .. '.' end )
end

-- {{{
local seps = {
	'==',
	'--',
	'- '
}

local function newSection( name, ref )
	return ([[

%s
%s
]]):format( seps[ ( select( 2, index:gsub( '%.', '' ) ) ) - 0 ]:rep( maxWidth / 2 ), ( '%s%+' .. maxWidth - #name ..'s' ):format( name, '*' .. docName .. ref .. '*' ) )
end

local function printBodies()
	for i, v in ipairs( bodies ) do
		print( v[1] )
		print( v[2] )
	end
end
-- }}}

local function addContent( ... )
	local info = { ... }
	for i, v in ipairs( info ) do
		for ii = 1, #v, 3 do
			local vv = v[ii]
			if type( vv ) == 'string' then
				increment()
				local tabs = (' '):rep( 4 * select( 2, index:gsub( '(%.)', '%1' ) ) )
				local ref = '|' .. docName .. v[2] .. '|'
				local name = ' ' .. v[1]
				print( tabs .. ( '%s%s%+' .. contentWidth - #index - #name + #ref - #tabs .. 's' ):format( index, name, ref ):gsub( '([%d%.%s]+%w+)(%s*)(|.*)', function( a, b, c ) return a .. ('.'):rep( #b ) .. c end ) .. '' )
				table.insert( bodies, { newSection( index .. ' ' .. v[1], v[2] ), ( v[3] or function() end )( v[1], v[2] ) } )
			else
				index = index .. '0.'
				for subelement = ii, #v do
					addContent( v[subelement] )
				end
				index = index:match( '^(.*%.)%d+%.$' )
				break
			end
		end
	end
end

local function wrap( text, tabs, offset )
    text = text .. ' '
	tabs = tabs or ''
	local str = text:match( '^(.-)%s' )
	local w = #str + ( offset or 0 )
	text:gsub( '%f[%S].-%f[%s]', function( word )
        word = word .. ' '
		w = w + #word
		if w > maxWidth then
			w = #word
			word = '\n' .. tabs .. word
		end
		str = str .. word
	end )
	return str:gsub( '~', ' ' ):sub( 1, -2 )
end

local function makeRef( str ) return str:gsub( '%.', '-' ) end

local function shallowReturn( element )
	local str = '\n'
	if not element then return 'None'
	else
		for i, v in ipairs( element ) do
			local temp = ( ' ' ):rep( 4 ) ..   '- ' .. v.name
			local ref = makeRef( '*' .. docName .. v.name .. '*' )
			str = str .. temp .. ( '%+' .. maxWidth - #temp .. 's\n' ):format( ref )
		end
		return str:sub( 1, -2 )
	end
end

local function makeVariant( index, tab, fail )
	local str = '- ' .. index:gsub( '(.)(.*)', function( a, b ) return a:upper() .. b .. ':' end )
	if tab[index] then
		for i, v in ipairs( tab[index] ) do
			str = str .. '\n' .. ( ' ' ):rep( 12 ).. wrap( '-~ ' .. v.name .. ': [' .. v.type .. '] ' .. v.description, ( ' ' ):rep( 14 ), 12 )
		end
		str = str .. '\n' .. ( ' ' ):rep( 4 )
	else
		str = str .. ' ' .. fail .. '\n    '
	end
	return str
end

local function generateVariants( tab )
	local str = ''
	str = str .. 'Variants:\n' .. ( ' ' ):rep( 4 )
	for i, v in ipairs( tab ) do
		str = str .. '- ' .. i .. ':\n' .. ( ' ' ):rep( 8 )
		str = str .. makeVariant( 'returns', v, 'Nothing' ) .. ( ' ' ):rep( 4 ) .. makeVariant( 'arguments', v, 'None' )
	end
	str = str:sub( 1, -6 )

	return str
end

local function createFunctions( tab, funcs, n )
	n = n and ( n ~= 'love' and n .. '.' ) or ''
	local new = {}
	for i, v in ipairs( funcs ) do
		local name = n .. v.name
		table.insert( new, { v.name, makeRef( name ), function()
			return generateVariants( v.variants )
		end } )
	end
	table.insert( tab, new )
end

local function prepend( parent, new )
	for i, v in ipairs( new ) do
		table.insert( parent, i, v )
	end
end

function love.load( a )
	-- {{{ Header
	--print
([[*love.txt*	Documentation for the LOVE game engine version %s

                      .sy+ :yy/
                      +NNm.hNNh
    /+                .+so+os+.    :+`                -+.   `.:+++/-.`
   :Md             `/hmdysssydmh/` +Mh`              -NN- .sdmhsssydmh+`
   hM:            .hNs-       -oNd. sMy             .mN: /Nm/`      .oNd.
   NM`            dM+           /Md  yMs           .mN/ :Mm.          yMo
   mM.           .Mm             mM. `hMo         .mN/  yM/         .+Nm.
   oMs           `MN`           `NM`  `yMs       -mN/   sM+     :+sdmdo.
   `hMs`          oMy`         `yMo    `yMy`    /Nm:    .NN:    ss+:.`
    `+mms:.`   `.  +mmo-`` `.-omm+       oNd: .sNh.      .hNy:.`  `` :+/.
      `:shdmmmmmd:  `/ydmmmmddy/`         -ymmmd/`        `:shdmmdmd-+s+-
          ```.```      ```.```              ````              ``````  ``

]]):format( api.config ) -- Get version string
	-- }}}
	print( newSection( 'CONTENT', 'content' ) )

	prepend( api.modules, { { name = 'love', description = 'General functions', functions = api.functions } } )
	local tab = { 'Modules', 'modules', function()
		return 'The modules for LOVE, i.e. love.graphics'
	end }
	for i, v in ipairs( api.modules ) do
		table.insert( tab, { v.name, makeRef( v.name ), function()
			local str = v.description .. '\n\n'
			str = str .. 'Types: '
			str = str .. shallowReturn( v.types )
			str = str .. '\nEnums: '
			str = str .. shallowReturn( v.enums )
			return str
		end } )
		createFunctions( tab, v.functions, v.name )
	end
	addContent( tab )
	
	-- enums
	-- callbacks
	--
	-- figure out why it does love-getSources-getSources

	printBodies()
end


love.event.quit()
