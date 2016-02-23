local api = require 'love-api.love_api'

local bodies = {}
local enums = {}
local types = {}
local maxWidth = 78
local contentWidth = 46
local index = '0.'
local docName = 'love-'

local function increment()
	index = index:gsub( '(.-)(%d+)%.$', function( a, b ) return a .. ( b + 1 ) .. '.' end )
end

local function makeRef( str ) return str:gsub( '%-', '.' ) .. '' end

local function rightAlign( ... )
	local elements = { ... }
	local last = ''
	local width = maxWidth
	if elements[#elements] == true then
		table.remove( elements, #elements )
		width = elements[#elements]
		table.remove( elements, #elements )
		last = elements[#elements]
		elements[#elements] = ' '
	end
	local length = width
	for i = 1, #elements - 1 do
		length = length - #elements[i]
	end
	return ( ( '%s' ):rep( #elements - 1 ) .. '%+' .. length .. 's' ):format( unpack( elements ) ) .. last
end

local function getLengthOfLongestLine( str )
	local length = #str:match( '^([^\n]*)\n?' )
	local last = #str:match( '\n?([^\n]*)$' )
	length = length > last and length or last
	str:gsub( '%f[^\n].-%f[\n]', function( a ) length = #a > length and #a or length end )
	return length
end

local function center( text )
	local str = ''
	if type( text ) == 'string' then
		local longest = getLengthOfLongestLine( text )
	text:gsub( 's*([^\n]+)\n?', function( a )
		local len = math.floor( ( maxWidth - longest ) / 2 )
		str = str .. ( ' ' ):rep( len ) .. a .. '\n' end )
	else
		for i, v in ipairs( text ) do
			str = str .. center( v )
		end
	end
	return str
end

local seps = {
	'==',
	'--',
	'--'
}

local function newSection( name, ref, shouldDotRef )
	return ([[

%s
%s
]]):format( seps[ ( select( 2, index:gsub( '%.', '' ) ) ) ]:rep( maxWidth / 2 ), rightAlign( name, ( shouldDotRef and makeRef or function( str ) return str end )( '*' .. docName .. ref .. '*' ) ) )
end

local function printBodies()
	for i, v in ipairs( bodies ) do
		print( v[1] )
		print( v[2] )
	end
end

local function addContent( shouldDotRefs, ... )
	local info = { ... }
	for i, v in ipairs( info ) do
		for ii = 1, #v, 4 do
			local vv = v[ii]
			if type( vv ) == 'string' then
				increment()
				local tabs = (' '):rep( 4 * select( 2, index:gsub( '(%.)', '%1' ) ) )
				local ref = ( shouldDotRefs and makeRef or function( str ) return str end )( '|' .. docName .. v[2] .. '|' )
				local name = ' ' .. v[1]
				print( rightAlign( tabs, index, name, ref, contentWidth, true ):gsub( '([%d%.%s]+%w+)(%s*)(%s|.*)', function( a, b, c ) return a .. ('.'):rep( #b ) .. c end ) .. '' )
				table.insert( bodies, { newSection( index .. ' ' .. v[1], v[2], v[4] ), ( v[3] or function() end )( v[1], v[2] ) } )
			else
				index = index .. '0.'
				for subelement = ii, #v do
					addContent( v[subelement][4], v[subelement] )
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
	offset = offset or #tabs
	local str = text:match( '^(.-%s)' )
	local w = #str + offset
	text:gsub( '%f[%S].-%f[%s]', function( word )
		word = word .. ' '
		w = w + #word
		if w > maxWidth then
			w = #( tabs .. word )
			word = '\n' .. tabs .. word
		end
		str = str .. word
	end )
	return str:gsub( '~', ' ' ):sub( 1, -2 )
end

local function shallowReturn( element )
	local str = '\n'
	if not element then return 'None'
	else
		for i, v in ipairs( element ) do
			local temp = ( ' ' ):rep( 4 ) ..   '- ' .. v.name
			local ref = '|' .. docName .. v.name .. '|'
			str = str .. rightAlign( temp, ref ) .. '\n'
		end
		return str:sub( 1, -2 )
	end
end

local function makeVariant( index, tab, fail )
	local str = '- ' .. index:gsub( '(.)(.*)', function( a, b ) return a:upper() .. b .. ':' end )
	if tab[index] then
		for i, v in ipairs( tab[index] ) do
			if enums[v.type] or types[v.type] then
				v.description = v.description .. ' See |' .. docName .. v.type .. '| for more.'
			end
			str = str .. '\n' .. ( ' ' ):rep( 12 ).. wrap( '- ' .. v.name .. ': <' .. v.type .. '> ' .. v.description, ( ' ' ):rep( 14 ), 12 )
		end
		str = str .. '\n' .. ( ' ' ):rep( 4 )
	else
		str = str .. ' ' .. fail .. '\n    '
	end
	return str
end

local function generateVariants( tab )
	local str = '\nVariants:\n' .. ( ' ' ):rep( 4 )
	for i, v in ipairs( tab ) do
		str = str .. i .. ':\n' .. ( ' ' ):rep( 8 )
		str = str .. makeVariant( 'arguments', v, 'None' ) .. ( ' ' ):rep( 4 ) .. makeVariant( 'returns', v, 'Nothing' )
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
			return wrap( v.description ) .. '\n' .. generateVariants( v.variants )
		end, true } )
	end
	table.insert( tab, new )
end

local function prepend( parent, new )
	for i, v in ipairs( new ) do
		table.insert( parent, i, v )
	end
end

function love.load( a )
	print( rightAlign( '*love.txt*', 'Documentation for the LOVE game framework version ' .. api.version .. '.' ),
	( [[


%s
%s]] ):format( center( [[

 _       o__o __      __ ______
| |     / __ \\ \    / //  ____\
| |    | |  | |\ \  / / | |__
| |    | |  | | \ \/ /  |  __|
| |____| |__| |  \  /   | |____
\______|\____/    \/    \______/

]] ), center{ 'The complete solution for Vim with LOVE.', 'Includes highlighting and documentation.' } ) )
	print( newSection( 'CONTENT', 'content' ) )

	for i, v in ipairs( api.modules ) do
		for ii, vv in ipairs( v.enums or {} ) do
			enums[vv.name] = true
		end
		for ii, vv in ipairs( v.types or {} ) do
			types[vv.name] = true
		end
	end
	for i, v in ipairs( api.types ) do
		types[v.name] = true
	end

	-- Modules
	prepend( api.modules, { { name = 'love', description = 'General functions', functions = api.functions } } )
	local tab = { 'Modules', 'modules', function()
		return 'The modules for LOVE, i.e. love.graphics'
	end, false }
	for i, v in ipairs( api.modules ) do
		table.insert( tab, { v.name, makeRef( v.name ), function()
			local str = v.description .. '\n\n'
			str = str .. '- Types: '
			str = str .. shallowReturn( v.types )
			str = str .. '\n- Enums: '
			str = str .. shallowReturn( v.enums )
			return str
		end, true } )
		createFunctions( tab, v.functions, v.name )
	end
	addContent( false, tab )

	-- Enums
	local tab = { 'Enums', 'enums', function()
		return 'Constants associated with specific functions.'
	end, false }
	for i, v in ipairs( api.modules ) do
		for ii, vv in ipairs( v.enums or {} ) do
			table.insert( tab, { vv.name, vv.name, function()
				local str = wrap( vv.description or 'ERROR: Nothing seems to be here. Check out the repo (https://github.com/love2d-community/love-api) and make a pull request' ) .. '\n'
				str = str .. '\nConstants:\n\n'
				for iii, vvv in ipairs( vv.constants ) do
					str = str .. ( ' ' ):rep( 4 ) .. vvv.name .. ( ' ' ):rep( contentWidth / 2 - #vvv.name ) .. wrap( vvv.description, ( ' ' ):rep( contentWidth / 2 + 4 ) ) .. '\n'
				end
				return str
			end, false } )
		end
	end
	addContent( false, tab )

	-- Callbacks
	-- Config flags

	printBodies()
end

love.event.quit()
