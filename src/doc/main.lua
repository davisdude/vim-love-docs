-- TODO:
-- Trim ref length for enums (see love-ParticleSystem:setTangentialAcceleration)
-- 		(In table of contents and actual reference)
-- Handle when synopsis is too long (see love.graphics.rectangle-2)
-- 		(Should not just have parenthesis at end of line; needs >= 1 arg)
-- Add more information and tags to enums and types

local api = require 'love-api.love_api'
local name = 'love'
local lineLength = 79
api.name = 'love'
api.description = 'General purpose functions'
table.insert( api.modules, 1, api )

api.callbacks.name = 'callbacks'
api.callbacks.description = 'Callbacks'
api.callbacks.functions = api.callbacks
table.insert( api.modules, 2, api.callbacks )

-- Header
print[[
*love.txt* *love2d*                 Documentation for the LOVE game framework.

                       _       o__o __      __ ______ ~
                      | |     / __ \\ \    / //  ____\~
                      | |    | |  | |\ \  / / | |__   ~
                      | |    | |  | | \ \/ /  |  __|  ~
                      | |____| |__| |  \  /   | |____ ~
                      \______|\____/    \/    \______/~

                   The complete solution for Vim with LOVE.
                   Includes highlighting and documentation.


]]

-- Generate keywords
local keywords = {}
for _, module in ipairs( api.modules ) do
	table.insert( keywords, module.name )
	for _, type in ipairs( module.types or {} ) do table.insert( keywords, type.name ) end
	for _, enum in ipairs( module.enums or {} ) do table.insert( keywords, enum.name ) end
end

local forbiddenPunctuation = ',?!(;'
local function makeKeyword( word ) return '|' .. word .. '|' end
local function makeKeywordIfKeyword( text )
	-- Cut off any following text
	local text, punctuation = text:match( '^([^' .. forbiddenPunctuation .. '@]*)([.' .. forbiddenPunctuation .. '@]?.*)$' )
	punctuation = punctuation or ''
	if text:match( 'love%.%l' ) then
		text = makeKeyword( text )
	else
		for _, v in ipairs( keywords ) do
			if v == text then
				text = makeKeyword( text )
				break
			elseif text:match( '^' .. v ) then
				if not text:match( '%-' ) then
					text = makeKeyword( text )
				end
			end
		end
	end
	return text .. punctuation
end

local function makeType( text )
	-- Keyword
	local keyword = makeKeywordIfKeyword( text )
	if keyword == text then keyword = '<' .. keyword .. '>' end
	return keyword
end

local function makeReference( str )
	return '*love-' .. str .. '*'
end

local function centerText( before, text, width )
	return before .. (' '):rep( width / 2 - #before - #text / 2 ) .. text
end

local function rightText( before, text, width )
	return before .. (' '):rep( width - #text - #before ) .. text
end

local function leftText( before, text )
	return before .. text
end

local function tab( n )
	n = n or 1
	local str = ''
	for i = 1, n do
		str = str .. (' '):rep( 4 )
	end
	return str
end

-- Modes are embedded in str
-- [str str]{mode}
-- modes:
-- 	- 'c': center
-- 	- 'r': right
-- 	- 't': indent
-- 		- '[first@s:second]tm': indent
-- 			- 'first' indicates the prefix for the first line
-- 			- '@s' indicates fixed-width mode
-- 			- ':second' indicates the (optional) prefix for all lines after the first line
-- 			- 'm' indicates the wrap mode. Nothing is left, r and c are right and center
-- Center must precede right, otherwise results will be messed up.
-- Indent must be the last part of the string
local function formattedPrint( str )
	local output = ''
	local centerStart, center = str:match( '()@%[(.-)@%]{c}' )
	local rightStart, right = str:match( '()@%[(.-)@%]{r}' )
	local tabStart, tab, wrapMode, tabAfter = str:match( '()@%[(.-)@%]{t(.?)}(.*)' )

	local pre, output = str, ''
	if right then
		pre = str:sub( 1, rightStart - 1 )
	end
	if center then
		pre = str:sub( 1, centerStart - 1 )
		output = centerText( pre, center, lineLength )
	end
	if not center then output = pre end

	if not tabStart then
		output = output .. (' '):rep( lineLength - #output - #right ) .. right
	else
		if not center and not right then
			output = str:sub( 1, tabStart - 1 )
		end

		local outFunc
		if wrapMode == 'r' then outFunc = rightText
		elseif wrapMode == 'c' then outFunc = centerText
		else outFunc = leftText end

		tabAfter = tabAfter or ''
		local fixedWidth = tab:match( '@s' )
		local afterFirstLine = tab:match( '@s:?(.-)$' )
		local spaceIndicator = afterFirstLine and tab:match( '^(.-)@' ) or tab
		afterFirstLine = afterFirstLine and afterFirstLine or spaceIndicator
		local indent = ( fixedWidth and (' '):rep( #output ) or '' ) .. afterFirstLine
		local width = lineLength - #indent
		local beforeRight = output .. spaceIndicator
		output = ''
		local currentLine = ''
		
		-- Add newline and spaces to make breaking easier
		tabAfter = tabAfter .. '\n'
		tabAfter:gsub( '(.-)\n', function( line )
			line = line .. ' '
			line:gsub( '(%S-)%s+', function( word )
				word = makeKeywordIfKeyword( word )
				if #beforeRight + #word > lineLength then
					while #beforeRight + #word > lineLength do
						local index = lineLength - #beforeRight - 1
						local onLine, nextLine = word:sub( 1, index ) .. '-', word:sub( index + 1 )
						output = output .. beforeRight .. onLine .. '\n'
						beforeRight = indent
						word = nextLine
						currentLine = ''
					end
				elseif #beforeRight + #currentLine + #word + 1 > lineLength then
					output = output .. beforeRight .. outFunc( '', currentLine:sub( 1, -2 ), width - ( not fixedWidth and #beforeRight or 0 ) ) .. '\n'
					beforeRight = indent
					currentLine = ''
				end
				currentLine = currentLine .. word .. ' '
			end )
			output = output .. beforeRight .. outFunc( '', currentLine:sub( 1, -2 ), width - ( not fixedWidth and #beforeRight or 0 ) ) .. '\n'
			currentLine = ''
			beforeRight = indent
		end )
		output = output:match( '^(.*)\n$' )
	end
	return output
end

local function reference( str )
	return formattedPrint( str .. '@[' .. makeReference( str ):lower() .. '@]{r}' )
end

local function increaseIndex( index )
	local first, last = index:match( '^(.-)(%d+)%.$' )
	last = tonumber( last ) + 1
	return first .. last .. '.'
end

local function increaseIncrement( index )
	return index .. '0.'
end

local function decreaseIncrement( index )
	return index:match( '^(.*%.)%d+%.$' )
end

local function section() return ('='):rep( lineLength ) end
local function subSection() return ('-'):rep( lineLength ) end

print( section() )
print( reference( 'CONTENTS' ) .. '\n' )

local referenceLength = 32
local preLength = lineLength - referenceLength
local index = '0.'
local lines = {}

local function printAspect( aspect, ref )
	moduleName = moduleName
	index = increaseIndex( index )
	local name = aspectName

	if #ref > referenceLength - 3 then ref = ref:sub( 1, referenceLength - 3 ) .. '-' end
	ref = '|' .. ref .. '|'

	aspect = tab( select( 2, index:gsub( '%.', '' ) ) ) .. index .. ' ' .. aspect
	if #aspect > preLength - 3 then aspect = aspect:sub( 1, preLength - 3 ) .. '-' end
	aspect = aspect .. ' ' .. ('.'):rep( preLength - #aspect - 2 ) .. ' '

	return aspect .. ref
end

local function tableConcat( tab, index, sep )
	local ret = {}
	for _, v in ipairs( tab ) do
		table.insert( ret, v[index] )
	end
	return table.concat( ret, sep )
end

local function getFunctionName( moduleName, name )
	local needsLove = moduleName ~= 'love' and 'love.' or ''
	local isCallback = moduleName == 'callbacks'
	return isCallback and 'love.' .. name or needsLove .. moduleName .. '.' .. name
end

local function printFunctionTable( func, t, indent )
	indent = indent or tab()
	local str = formattedPrint( indent .. t.name .. '@[' .. makeReference( func .. '-' .. t.name ) .. '@]{r}' ) .. '\n\n'
	indent = indent .. tab()
	for _, v in ipairs( t.table ) do
		str = str .. formattedPrint( indent .. v.name .. '@[' .. makeReference( func .. '-' .. t.name .. '-' .. v.name ) .. '@]{r}' ) 
			.. '\n\n' .. formattedPrint( indent .. tab() .. '@[@s@]{t}' .. v.description ) .. '\n\n'

		if v.table then
			str = str .. '\n\n' .. printFunctionTable( func .. '-' .. t.name, v, indent .. tab() )
		end
	end
	return str
end

local function printFunctionVariants( index, func, name )
	local synopsis = ( func.returns and tableConcat( func.returns, 'name', ', ' ) .. ' = ' or '' ) 
		.. name 
		..  '(' .. ( func.arguments and ' ' .. tableConcat( func.arguments, 'name', ', ' ) .. ' ' or '' ) .. ')'

	local variant = formattedPrint( tab() .. index .. ': @[@s@]{t}' .. ( func.description or 'See function description.' ) .. '\n\n' .. synopsis ) .. '\n\n'
	if func.arguments then
		variant = variant .. tab( 2 ) .. '- Arguments:\n'
		for _, arg in ipairs( func.arguments ) do
			variant = variant .. formattedPrint( tab( 3 ) .. '- ' .. arg.name .. ': @[@s@]{t}' .. makeType( arg.type ) .. ' ' .. arg.description ) .. '\n'
			
			if arg.table then
				variant = variant .. '\n' .. printFunctionTable( name, arg )
			end
		end
	else
		variant = variant .. tab( 2 ) .. '- Arguments: None\n'
	end

	if func.returns then
		variant = variant .. tab( 2 ) .. '- Returns:\n'
		for _, ret in ipairs( func.returns ) do
			variant = variant .. formattedPrint( tab( 3 ) .. '- ' .. ret.name .. ': @[@s@]{t}' .. makeType( ret.type ) .. ' ' .. ret.description ) .. '\n'

			if ret.table then
				variant = variant .. '\n' .. printFunctionTable( name, ret )
			end
		end
	else
		variant = variant .. tab( 2 ) .. '- Returns: Nothing\n'
	end

	return variant
end

local function printFunction( index, func, name )
	local str = subSection() 
		.. '\n' 
		.. formattedPrint( index .. ' ' .. func.name .. '@[' .. makeReference( name ) .. '@]{r}' ) .. '\n\n'
		.. formattedPrint( '@[@]{t}' .. func.description )
		.. '\n\nVariants:\n\n'

	for i, variation in ipairs( func.variants ) do
		str = str .. printFunctionVariants( i, variation, name ) .. '\n'
	end
	return str:match( '^(.*)\n$' )
end

local function listElements( t, element, index, reference )
	local str = ''
	if t[element] then
		for _, v in ipairs( t[element] ) do
			str = str .. '\n' .. formattedPrint( tab() .. '- ' .. index( v ) .. '@[' .. reference( v ) .. '@]{r}' )
		end
	else
		str = ' None'
	end
	return str .. '\n\n'
end

-- api.modules = { api.modules[3] }
local postLines = {}
local types, enums, typePost, enumPost
for _, module in ipairs( api.modules ) do
	print( printAspect( module.name, 'love-' .. module.name ) )

	table.insert( lines, section() )
	table.insert( lines, formattedPrint( index .. ' ' .. module.name .. '@[@]{tr}*love-' .. module.name .. '*\n' ) )
	table.insert( lines, formattedPrint( '@[@]{t}' .. module.description .. '\n' ) )

	index = increaseIncrement( index )
	postLines = {}
	for _, func in ipairs( module.functions or {} ) do
		local name = getFunctionName( module.name, func.name )
		print( printAspect( func.name, 'love-' .. name ) )

		table.insert( postLines, printFunction( index, func, name ) )
	end

	if module.types then
		print( printAspect( 'types', 'love-' .. module.name .. '-types' ) )
		types = '- Types:\n'
		typePost = ''

		table.insert( postLines, subSection() )
		table.insert( postLines, formattedPrint( index .. ' types@[' .. makeReference( module.name .. '-types' ) .. '@]{r}' ) .. '\n\nThe types of ' .. module.name .. ':\n' )
		index = increaseIncrement( index )

		for _, type in ipairs( module.types ) do
			print( printAspect( type.name, 'love-' .. type.name ) )

			typePost = typePost .. subSection() .. '\n' 
				.. formattedPrint( index .. ' ' .. type.name .. '@[' .. makeReference( type.name ) .. '@]{r}' ) .. '\n\n'
				.. formattedPrint( '@[@]{t}' .. type.description ) 
				.. '\n\nConstructors:' .. listElements( type, 'constructors', 
					function( v ) return v end,
					function( v ) return makeKeyword( 'love-' .. getFunctionName( module.name, v ) ) end
				) .. 'Supertypes:' .. listElements( type, 'supertypes',
					function( v ) return v end,
					function( v ) return '|love-' .. v .. '|' end
				) .. 'Subtypes:' .. listElements( type, 'subtypes',
					function( v ) return v end,
					function( v ) return '|love-' .. v .. '|' end
				) .. 'Functions: ' .. listElements( type, 'functions',
					function( v ) return v.name end,
					function( v ) return '|love-' .. type.name .. ':' .. v.name .. '|' end
				)

			types = types .. formattedPrint( tab() .. '- ' .. type.name .. '@[' .. makeKeyword( 'love-' .. type.name ) .. '@]{r}' ) .. '\n'
			index = increaseIncrement( index )

			for _, func in ipairs( type.functions or {} ) do
				print( printAspect( func.name, 'love-' .. type.name .. ':' .. func.name ) )

				typePost = typePost .. printFunction( index, func, type.name .. ':' .. func.name )
			end
			index = decreaseIncrement( index )
		end

		table.insert( lines, types )
		table.insert( postLines, types:match( '^[^\n]-\n(.*)$' ) )
		table.insert( postLines, typePost )
		index = decreaseIncrement( index )
	else
		table.insert( lines, '- Types: None\n' )
	end

	if module.enums then
		print( printAspect( 'enums', 'love-' .. module.name .. '-enums' ) )
		enums = '- Enums:\n'
		enumPost = ''

		table.insert( postLines, subSection() )
		table.insert( postLines, formattedPrint( index .. ' enums@[' .. makeReference( module.name .. '-enums' ) .. '@]{r}' ) .. '\n\nThe enums of ' .. module.name .. ':\n' )
		index = increaseIncrement( index )

		for _, enum in ipairs( module.enums ) do
			print( printAspect( enum.name, 'love-' .. enum.name ) )
			enums = enums .. formattedPrint( tab() .. '- ' .. enum.name .. '@[' .. makeKeyword( 'love-' .. enum.name ) .. '@]{r}' ) .. '\n'
			enumPost = enumPost .. subSection() .. '\n' 
				.. formattedPrint( index .. ' ' .. enum.name .. '@[' .. makeReference( enum.name ) .. '@]{r}' ) .. '\n\n'
				.. formattedPrint( '@[@]{t}' .. enum.description ) .. '\n\n'

			for _, const in ipairs( enum.constants ) do
				enumPost = enumPost .. formattedPrint( const.name .. '@[' .. makeReference( enum.name .. '-' .. const.name ) .. '@]{r}' ) .. '\n\n'
					.. formattedPrint( '@[' .. tab() .. '@]{t}' .. const.description ) .. '\n\n'
					.. ( const.notes and formattedPrint( tab() .. 'NOTE: @[@s@]{t}' .. const.notes ) .. '\n\n' or '' )
			end
		end

		table.insert( lines, enums )
		table.insert( postLines, enums:match( '^[^\n]-\n(.*)$' ) )
		table.insert( postLines, enumPost )
		index = decreaseIncrement( index )
	else
		table.insert( lines, '- Enums: None\n' )
	end

	for i = 1, #postLines do table.insert( lines, postLines[i] ) end

	index = decreaseIncrement( index )
end

print( printAspect( 'about', 'love-about' ) )
table.insert( lines, section() )
table.insert( lines, formattedPrint( index .. ' about@[*love-about*@]{r}' ) .. '\n' )
table.insert( lines, formattedPrint( ( [[
@[@]{t}For LOVE (http://love2d.org) version %s.

Generated from

    https://github.com/love2d-community/love-api

using

    https://github.com/davisdude/vim-love-docs

Made by Davis Claiborne under the MIT license. See LICENSE.md for more info.
]] ):format( api.version ) ) )

print()
for _, line in ipairs( lines ) do
	print( line )
end
