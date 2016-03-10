local api = require 'love-api.love_api'

local bodies = {}
local functions = {}
local types = {}
local enums = {}
local tags = {}
local maxWidth = 78
local contentWidth = 46
local docLen = 24
local index = '0.'
local docName = 'love.'
local lovePrefix = docName:sub( 1, -2 )

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

local function replaceTextWithRef( pre, text )
	local custPunc = '%.%?,;<>!:'
	return text:gsub( '%f[%w' .. custPunc .. ']([' .. custPunc .. ']*)(' .. pre .. '.-)([' .. custPunc .. ']*)%f[^%w' .. custPunc .. ']', function( first, word, post )
		return first .. '|' .. word .. '|' .. post
	end  ) .. ''
end

local function preventDuplicateTags( tag )
	if tags[tag] then
		tag = tag:gsub( '^%*(.+)%-?(%d*)%*', function( front, number )
			number = #number > 0 and number + 1 or 2
			return front .. '-' .. number .. '*'
		end )
	end
	tags[tag] = true
	return tag
end

local function wrap( text, tabs, offset, initialLength )
	text = replaceTextWithRef( 'love%.', text )
	for i in pairs( types ) do text = replaceTextWithRef( i, text ) end
	for i in pairs( enums ) do text = replaceTextWithRef( i, text ) end

	tabs = tabs or ''
	offset = offset or ''
	text = text:gsub( '\n\n', '\n \n' ) -- Make new lines show up
	text = text:gsub( '\n( +)(%S)', function( str, next ) return '\n' .. ( '#' ):rep( #str ) .. next end ) .. '\n'
	local rows = {}
	local first = true
	local currentWidth = 0
	text:gsub( '(.-\n)', function( line )
		local len = not first and #tabs + #offset or ( initialLength or 0 )
		local str = not first and ( ' ' ):rep( len ) or ''
		first = false
		line:gsub( '(%S+)%s', function( word )
			len = len + #word + 1 -- + 1 for space
			if len > maxWidth then
				table.insert( rows, str )
				str = tabs .. offset .. word
				len = #str
			else
				str = str .. ( #str:match( '^(%s*)' ) < #str and ' ' or '' ) .. word
			end
		end )
		table.insert( rows, str )
	end )
	local inCodeBlock = false
	return table.concat( rows, '\n' ):gsub( '\n(%s*)(%#*)', function( spaces, formatting ) return '\n' .. spaces .. ( ' ' ):rep( #formatting ) end ) .. ''
end

local function formatLikeVim( index, text, refTab )
	local refs = ''
	for i = 1, #refTab do refs = refs .. preventDuplicateTags( '*' .. refTab[i] .. '* ' ) end
	refs = refs:sub( 1, -2 )
	local str = '\n' .. rightAlign( '', refs ) .. '\n'
	str = str .. index .. ( ' ' ):rep( docLen - #index ) .. wrap( text, ( ' ' ):rep( docLen ), '', docLen )
	return str
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
		local tag = preventDuplicateTags( '*' .. ref[i] .. '*' )
		str = str .. ( #ref[i] > 0 and ( tag .. ' ' ) or '' )
	end
	str = str:sub( 1, -2 )

	local header = seps[ ( select( 2, index:gsub( '%.', '' ) ) ) ]:rep( maxWidth )

	-- Wrap refs if they are too long
	local rows = {}
	if #first + #str > maxWidth then
		local currentWidth = #first
		local currentStr = ''
		str:gsub( '(*.-*)', function( sub )
			currentWidth = currentWidth + #sub + 1
			if currentWidth > maxWidth then
				table.insert( rows, currentStr )
				currentStr = sub
			else
				currentStr = currentStr .. ' ' .. sub
			end
		end )
		table.insert( rows, currentStr )
	else
		rows = { str }
	end
	str = rightAlign( name, rows[1] )
	for i = 2, #rows do str = str .. '\n' .. rightAlign( '', rows[i] ) end
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
				local ref = ( v[4] and function( str ) return str end or function( str ) return str:gsub( '%.', '-' ) end )( '|' 
					.. ( #v[2][1] + contentWidth + 3 <= maxWidth and v[2][1] or v[2][1]:sub( 1, maxWidth - contentWidth - 3 ) .. '-' ) .. '|' )
				local name = ' ' .. v[1]

				-- Trim names that are too long
				if #name + #tabs + #index > contentWidth then
					name = name:sub( 1, contentWidth - #tabs - #index - 2 ) .. '-'
				end
				print( rightAlign( tabs, index, name, ref, contentWidth, true ):gsub( '([%d%.%s]+%w+%s)(%s*)(%s|.*)', function( a, b, c )
					return a .. ( '.' ):rep( #b ) .. c 
				end ) .. '' )
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

local function shallowReturn( element, pre )
	local str = ''
	if not element then return 'None'
	else
		for i, v in ipairs( element ) do
			local name = v.name or v
			local temp = ( ' ' ):rep( 4 ) ..   '- ' .. name
			local ref = '|' .. ( pre and pre .. name or lovePrefix .. name ) .. '|'

			str = str .. '\n' .. rightAlign( temp, ref )
		end
		return str
	end
end

local function recursiveTable( tab, parentStr )
	parentStr = parentStr or ''
	local str = ''
	if tab.table then
		for _, v in ipairs( tab.table ) do
			local n = parentStr .. '.' .. v.name
			str = str .. formatLikeVim( v.name, replaceTextWithRef( parentStr .. '%.', v.description ), { n } ) .. '\n'
			str = str .. recursiveTable( v, n )
		end
	end
	return str
end

local function makeVariant( index, tab, fail, parentName )
	-- Capitalize first letter
	local str = '- ' .. index:gsub( '(.)(.*)', function( a, b ) return a:upper() .. b .. ':' end )
	if tab[index] then
		for i, v in ipairs( tab[index] ) do
			local vtype = v.type:sub( 1, 1 ):match( '%u' ) and v.type or '<' .. v.type .. '>'
			str = str .. '\n' .. ( ' ' ):rep( 12 ).. wrap( '- ' .. v.name .. ': ' .. vtype .. ' ' .. v.description, ( ' ' ):rep( 12 ), ( ' ' ):rep( 2 ), 8 + #( '- ' .. index ) )
			if v.table then
				local tag = preventDuplicateTags( '*' .. parentName .. '-' .. v.name .. '*' )
				str = str .. '\n\n' .. rightAlign( '', tag ) .. '\n'
				str = str .. recursiveTable( v, parentName .. '-' .. v.name )
			end
		end
		str = str .. '\n' .. ( ' ' ):rep( 4 )
	else
		str = str .. ' ' .. fail .. '\n    '
	end
	return str
end

local function generateVariants( tab, parentName )
	local str = '\nVariants:\n' .. ( ' ' ):rep( 4 )
	for i, v in ipairs( tab ) do
		str = str .. i .. ':\n' .. ( ' ' ):rep( 8 )
		str = str .. ( v.description and '- Description: ' .. wrap( v.description, '', ( ' ' ):rep( 10 ), #'        - Description: ' ) .. '\n' .. ( ' ' ):rep( 8 ) or '' )
		          .. makeVariant( 'arguments', v, 'None', parentName ) .. ( ' ' ):rep( 4 )
		          .. makeVariant( 'returns', v, 'Nothing', parentName )
	end
	str = str:sub( 1, -6 )

	return str
end

local function createFunctions( tab, funcs, n )
	n = n and ( n ~= 'love' and n .. '.' ) or ''
	local new = {}
	for i, v in ipairs( funcs ) do
		local name = docName .. n .. v.name
		functions[name] = true
		table.insert( new, { v.name, docName .. n .. v.name, function()
			return wrap( v.description ) .. '\n' .. generateVariants( v.variants, name )
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
	print( newSection( 'CONTENT', lovePrefix .. '-content' ) )

	prepend( api.modules, { { name = 'love', description = 'General functions' } } )
	mixin( api.modules[1], api )

	for i, v in ipairs( api.modules ) do
		for ii, vv in ipairs( v.types or {} ) do
			types[vv.name] = vv
		end
	end
	for i, v in ipairs( api.modules ) do
		for ii, vv in ipairs( v.enums or {} ) do
			enums[vv.name] = vv
		end
	end

	local tab = { 'modules', lovePrefix .. '-modules', function() return 'All LOVE modules and their functions, enums, and types.' end, false }
	for i, v in ipairs( api.modules ) do
		local new = { v.name, docName .. v.name, function()
			local str = wrap( v.description ) .. '\n\n'
			str = str .. '- Types: '
			str = str .. shallowReturn( v.types, lovePrefix .. '-' )
			str = str .. '\n- Enums: '
			str = str .. shallowReturn( v.enums, lovePrefix .. '-' )
			return str
		end, true }

		-- Functions
		table.insert( new, { 'functions', ( v.name ~= 'love' and docName .. v.name or lovePrefix ) .. '-functions', function() return wrap( 'The functions of ' .. v.name .. '.' ) end, true } )
		createFunctions( new, v.functions, v.name )

		-- Types
		if v.types then
			table.insert( new, { 'types', ( v.name ~= 'love' and docName .. v.name or lovePrefix ) .. '-types', function()
				local str = wrap( 'The types of ' .. v.name .. ':' ) .. '\n'
				return str .. shallowReturn( v.types, lovePrefix .. '.' )
			end, true } )
			local stack = {}
			local n = v.name and ( v.name ~= 'love' and docName ) or ''
			for ii, vv in ipairs( v.types ) do
				table.insert( stack, { vv.name, { lovePrefix .. '-' .. vv.name, ( ( n .. v.name ~= 'love' ) and ( n .. v.name .. '-' .. vv.name ) or '' ) }, function()
					local str = wrap( vv.description )
					str = str .. '\n\nConstructors: ' .. shallowReturn( vv.constructors, docName .. v.name .. '.' )
					str = str .. '\n\nSupertypes: ' .. shallowReturn( vv.supertypes, lovePrefix .. '-' )
					str = str .. '\n\nSubtypes: ' .. shallowReturn( vv.subtypes, lovePrefix .. '-' )
					str = str .. '\n\nFunctions: ' .. shallowReturn( vv.functions, vv.name .. ':' )
					for iii, vvv in ipairs( vv.supertypes or {} ) do
						str = str .. ( types[vvv].functions and shallowReturn( types[vvv].functions, types[vvv].name .. ':' ) or '' )
					end
					return str
				end, false } )
				local temp = {}
				for iii, vvv in pairs( vv.functions or {} ) do
					local name = vv.name .. ':' .. vvv.name
					table.insert( temp, { vvv.name, name, function()
						return wrap( vvv.description ) .. ( vvv.variants and '\n' .. generateVariants( vvv.variants, vvv.name ) or '' )
					end, false } )
				end
				table.insert( stack, temp )
			end
			table.insert( new, stack )
		end

		-- Enums
		if v.enums then
			table.insert( new, { 'enums', ( v.name ~= 'love' and docName .. v.name or lovePrefix ) .. '-enums', function()
				local str = 'Enums within ' .. docName .. v.name .. ':'
				for ii, vv in ipairs( v.enums ) do
					str = str .. '\n' .. rightAlign( ( ' ' ):rep( 4 ) .. vv.name, '|' .. docName .. vv.name .. '|' )
				end
				return str
			end, true } )
			local stack = {}
			for ii, vv in ipairs( v.enums ) do
				table.insert( stack, { vv.name, { lovePrefix .. '-' .. vv.name, docName .. v.name .. '-' .. vv.name }, function()
					local str = wrap( vv.description ) .. '\n'
					local tag = preventDuplicateTags( '*' .. vv.name .. '-constants*' )
					str = str .. '\n' .. rightAlign( 'Constants:', tag ) .. '\n'
					for iii, vvv in ipairs( vv.constants ) do
						str = str ..  formatLikeVim( vvv.name, vvv.description, { vv.name .. '-' .. vvv.name } ) .. '\n'
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
	tab = { 'callbacks', lovePrefix .. '-callbacks', function() return 'All LOVE callbacks.' end, false }
	createFunctions( tab, api.callbacks )
	for i = #tab[5], 1, -1 do
		tab[i + 5] = tab[5][i]
		tab[5][i] = nil
	end
	addContent( tab )

	addContent{ 'About', lovePrefix .. '-' .. 'about', function()
		return wrap( ( [[For LOVE (http://love2d.org) version %s.

Generated from

####https://github.com/love2d-community/love-api 

using

####https://github.com/davisdude/vim-love-docs

Made by Davis Claiborne under the zlib license. See LICENSE.md for more info. ]] ):format( api.version ), '', '' )
	end, true }

	-- Prevent "love" from being wrapped at the end of sentences (see 1.1.1)

	printBodies()
end

love.event.quit()
