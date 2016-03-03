local api = require 'love-api.love_api'

local bodies = {}
local maxWidth = 78
local contentWidth = 46
local index = '0.'
local docName = 'love.'

local function increment()
	index = index:gsub( '(.-)(%d+)%.$', function( a, b ) return a .. ( b + 1 ) .. '.' end )
end

local function rightAlign( ... ) -- If last argument is true, right align to ...[# - 1], put ...[#] at end
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
			str = str .. ( ' ' ):rep( ( maxWidth - longest ) / 2 ) .. a .. '\n'
		end )
	else
		for i, v in ipairs( text ) do
			str = str .. center( v )
		end
	end
	return str
end

local seps = setmetatable( {
	'=',
	'-',
}, {
	__index = function( tab ) return tab[2] end
} )

local function newSection( name, ref )
	local str = ''
	local first = name

	ref = type( ref ) == 'table' and ref or { ref }
	for i = 1, #ref do
		str = str .. ( #ref[i] > 0 and ( '*' .. ref[i] .. '*' .. ' ' ) or '' )
	end
	str = str:sub( 1, -2 )

	local header = seps[ ( select( 2, index:gsub( '%.', '' ) ) ) ]:rep( maxWidth )

	-- Wrap refs if they are too long
	if #first + #str > maxWidth then
		local currentWidth = #first
		local currentStr = ''
		local rows = {}
		str:gsub( '(*.-*)', function( str )
			local cur = ' ' .. str
			currentWidth = currentWidth + #cur
			if currentWidth > maxWidth then
				table.insert( rows, currentStr )
				currentStr = str
			else
				currentStr = currentStr .. ' ' .. cur
			end
		end )
		table.insert( rows, currentStr )

		str = rightAlign( name, rows[1] ) .. '\n'
		for i = 2, #rows do
			str = str .. rightAlign( rows[i] ) .. '\n'
		end
	else
		str = rightAlign( name, str )
	end
	return '\n' .. header .. '\n' .. str .. '\n'
end

local function printBodies()
	for i, v in ipairs( bodies ) do
		print( v[1] ) -- Header
		print( v[2] ) -- Content
	end
end

local function addContent( ... )
	local info = { ... }
	for i, v in ipairs( info ) do
		for ii = 1, #v, 4 do -- { name, ref, body, shouldDotRef, ... }
			if type( v[ii] ) == 'string' then
				-- Allow for multiple refs
				v[2] = type( v[2] ) == 'table' and v[2] or { v[2] }
				increment()
				local tabs = ( ' ' ):rep( 2 * select( 2, index:gsub( '(%.)', '' ) ) )
				local ref = ( v[4] and function( str ) return str end or function( str ) return str:gsub( '%.', '-' ) end )( '|' .. v[2][1] .. '|' )
				local name = ' ' .. v[1]

				-- Trim names that are too long
				if #name + #tabs + #index > contentWidth then
					name = name:sub( 1, contentWidth - #tabs - #index - 2 ) .. '-'
				end
				print( rightAlign( tabs, index, name, ref, contentWidth, true ):gsub( '([%d%.%s]+%w+%s)(%s*)(%s|.*)', function( a, b, c ) return a .. ( '.' ):rep( #b ) .. c end ) .. '' )
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
	tabs = tabs or ''
	offset = offset or tabs
	local rows = {}
	text = '\n' .. text:gsub( '\n\n', '\n \n' ) .. '\n'
	text:gsub( '%f[^\n](.-)[\n]', function( word )
		local str = word:match( '^(.-)%s' )
		word:gsub( '%s(%S+)', function( sub )
			local len = #str + #offset + #tabs
			if len + #sub > maxWidth then
				table.insert( rows, str )
				str = tabs .. offset .. sub
			else
				str = str .. ' ' .. sub
			end
		end )
		table.insert( rows, str )
	end )
	return table.concat( rows, '\n' )
end

local function shallowReturn( element, pre )
	local str = ''
	if not element then return 'None'
	else
		for i, v in ipairs( element ) do
			local name = v.name or v
			local temp = ( ' ' ):rep( 4 ) ..   '- ' .. name
			local ref = '|' .. ( pre and pre .. name or docName:sub( 1, -2 ) .. name ) .. '|'

			str = str .. '\n' .. rightAlign( temp, ref )
		end
		return str
	end
end

local function makeVariant( index, tab, fail )
	-- Capitalize first letter
	local str = '- ' .. index:gsub( '(.)(.*)', function( a, b ) return a:upper() .. b .. ':' end )
	if tab[index] then
		for i, v in ipairs( tab[index] ) do
			str = str .. '\n' .. ( ' ' ):rep( 12 ).. wrap( '- ' .. v.name .. ': <' .. v.type .. '> ' .. v.description, ( ' ' ):rep( 2 ), ( ' ' ):rep( 12 ) )
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
		table.insert( new, { v.name, docName .. n .. v.name, function()
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

local function mixin( old, new )
	for i, v in pairs( new ) do
		old[i] = old[i] or v
	end
end

function love.load( a )
	print( rightAlign( '*love.txt*', '  Documentation for the LOVE game framework.' ),
	( [[


%s
%s]] ):format( center( [[
 _       o__o __      __ ______ ~
| |     / __ \\ \    / //  ____\~
| |    | |  | |\ \  / / | |__   ~
| |    | |  | | \ \/ /  |  __|  ~
| |____| |__| |  \  /   | |____ ~
\______|\____/    \/    \______/~
]] ), center{ 'The complete solution for Vim with LOVE.', 'Includes highlighting and documentation.' } ) )
	print( newSection( 'CONTENT', docName:sub( 1, -2 ) .. '-content' ) )

	prepend( api.modules, { { name = 'love', description = 'General functions' } } )
	mixin( api.modules[1], api )

	addContent{ 'About', docName:sub( 1, -2 ) .. '-' .. 'about', function()
		return wrap( ( [[For LOVE (http://love2d.org) version %s.

Generated from https://github.com/love2d-community/love-api using https://github.com/davisdude/vim-love-docs

Made by Davis Claiborne under the zlib license. See LICENSE.md for more info. ]] ):format( api.version ), '', '  ' )
	end, true }

	local tab = { 'modules', docName:sub( 1, -2 ) .. '-modules', function() return 'All LOVE modules and their functions, enums, and types.' end, false }
	for i, v in ipairs( api.modules ) do
		local new = { v.name, docName .. v.name, function()
			local str = wrap( v.description ) .. '\n\n'
			str = str .. '- Types: '
			str = str .. shallowReturn( v.types, docName:sub( 1, -2 ) .. '-' )
			str = str .. '\n- Enums: '
			str = str .. shallowReturn( v.enums, docName:sub( 1, -2 ) .. '-' )
			return str
		end, true }

		-- Functions
		table.insert( new, { 'functions', ( v.name ~= 'love' and docName .. v.name or docName:sub( 1, -2 ) ) .. '-functions', function() return wrap( 'The functions of ' .. v.name .. '.' ) end, true } )
		createFunctions( new, v.functions, v.name )

		-- Types
		if v.types then
			table.insert( new, { 'types', ( v.name ~= 'love' and docName .. v.name or docName:sub( 1, -2 ) ) .. '-types', function()
				local str = wrap( 'The types of ' .. v.name .. ':' ) .. '\n'
				return str .. shallowReturn( v.types, docName:sub( 1, -2 ) .. '.' )
			end, true } )
			local stack = {}
			local n = v.name and ( v.name ~= 'love' and docName ) or ''
			for ii, vv in ipairs( v.types ) do
				table.insert( stack, { vv.name, { docName:sub( 1, -2 ) .. '-' .. vv.name, ( ( n .. v.name ~= 'love' ) and ( n .. v.name .. '-' .. vv.name ) or '' ) }, function()
					local str = wrap( vv.description )
					str = str .. '\n\nConstructors: ' .. shallowReturn( vv.constructors, docName .. v.name .. '.' )
					str = str .. '\n\nSupertypes: ' .. shallowReturn( vv.supertypes, docName:sub( 1, -2 ) .. '-' )
					str = str .. '\n\nSubtypes: ' .. shallowReturn( vv.subtypes, docName:sub( 1, -2 ) .. '-' )
					str = str .. '\n\nFunctions: ' .. shallowReturn( vv.functions, vv.name .. ':' )
					return str
				end, false } )
				local temp = {}
				for iii, vvv in pairs( vv.functions or {} ) do
					local name = vv.name .. ':' .. vvv.name
					table.insert( temp, { vvv.name, name, function()
						return wrap( vvv.description ) .. ( vvv.variants and '\n' .. generateVariants( vvv.variants ) or '' )
					end, false } )
				end
				table.insert( stack, temp )
			end
			table.insert( new, stack )
		end

		-- Enums
		if v.enums then
			table.insert( new, { 'enums', ( v.name ~= 'love' and docName .. v.name or docName:sub( 1, -2 ) ) .. '-enums', function()
				local str = 'Enums within ' .. docName .. v.name .. ':'
				for ii, vv in ipairs( v.enums ) do
					str = str .. '\n' .. rightAlign( ( ' ' ):rep( 4 ) .. vv.name, '|' .. docName .. vv.name .. '|' )
				end
				return str
			end, true } )
			local stack = {}
			for ii, vv in ipairs( v.enums ) do
				table.insert( stack, { vv.name, { docName:sub( 1, -2 ) .. '-' .. vv.name, docName .. v.name .. '-' .. vv.name }, function()
					local str = wrap( vv.description ) .. '\n'
					str = str .. '\nConstants:\n\n'
					for iii, vvv in ipairs( vv.constants ) do
						str = str .. ( ' ' ):rep( 4 ) .. vvv.name .. ( ' ' ):rep( contentWidth / 2 - #vvv.name ) .. wrap( vvv.description, ( ' ' ):rep( contentWidth / 2 + 4 ) ) .. '\n'
					end
					return str:sub( 1, -2 )
				end, false } )
			end
			table.insert( new, stack )
		end

		table.insert( tab, new )
	end
	addContent( tab )

	-- Callbacks
	-- Config flags

	printBodies()
end

love.event.quit()
