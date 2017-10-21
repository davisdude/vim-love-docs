local api = require( 'love-api.love_api' )
local align = require( 'align' )

-- Local variables {{{
local INDENT_STRING = '    '
local TAG_PREFIX = 'love-'

local PAGE_WIDTH = 79
align.setDefaultWidth( PAGE_WIDTH )

local TOC_NAME_WIDTH_LIMIT = 40
-- The 2 is for spacing
local TOC_REF_WIDTH_LIMIT = PAGE_WIDTH - TOC_NAME_WIDTH_LIMIT - 2
-- }}}

-- Misc. functions {{{
local function getIndentation( indentLevel, indentString, defaultIndentLevel )
	indentLevel = indentLevel or defaultIndentLevel or 0
	indentString = indentString or INDENT_STRING
	local indent = indentString:rep( indentLevel )

	return indentLevel, indentString, indent
end

local function trimFormattedText( str, width, formatFunc )
	local formattedStr = formatFunc( str )

	-- Allows for the formatting func perform differently based on #str
	while #formattedStr > width do
		str = str:sub( 1, -2 )
		formattedStr = formatFunc( str .. '-' )
	end

	return formattedStr
end
-- }}}

-- Formatting functions {{{
local function formatAsTag( str )
	return ('*%s*'):format( str )
end

local function formatAsReference( str )
	return ('|%s|'):format( str )
end

-- Formats arguments and return values
-- Don't actually know if there's a specific name for this type of formatting...
local function formatSpecial( str )
	return ('`%s`'):format( str )
end

local function formatAsType( str )
	return ('<%s>'):format( str )
end

local function concat( tab, sep, func )
	local elements = {}

	for i, v in ipairs( tab ) do
		table.insert( elements, func( i, v ) )
	end

	return table.concat( elements, sep )
end

local function concatAttribute( tab, sep, attr, formatFunc )
	formatFunc = formatFunc or function( v ) return v end
	return concat( tab, sep, function( _, v )
		return formatFunc( v[attr] )
	end )
end
-- }}}

-- Functions {{{
-- Synopsis: return1, return2 = func( arg1, arg2 )
local function getSynopsis( variant, fullName )
	local synopsis = formatAsReference( fullName )

	-- Return values
	if #( variant.returns or {} ) > 0 then
		local returns = concatAttribute( variant.returns, ', ', 'name', formatSpecial )
		synopsis = returns .. ' = ' .. synopsis
	end

	-- Arguments
	if #( variant.arguments or {} ) == 0 then
		synopsis = synopsis .. '()'
	else
		local arguments = concatAttribute( variant.arguments, ', ', 'name', formatSpecial )
		synopsis = synopsis .. '( ' .. arguments .. ' )'
	end

	return synopsis
end

-- Assembles a list of a function's synopses
local function getSynopses( func, fullName )
	local synopses = {}

	for _, variant in ipairs( func.variants ) do
		table.insert( synopses, getSynopsis( variant, fullName ) )
	end

	return synopses
end

-- Lists all of a function's synopses
local function getFormattedSynopses( func, fullName, indentLevel, indentString )
	local indent
	indentString, indent = select( 2, getIndentation( indentLevel, indentString ) )

	local list = {}

	local synopses = getSynopses( func, fullName )
	for index, synopsis in ipairs( synopses ) do
		-- Account for synopses that could span multiple lines
		table.insert( list, align.left(
			-- Pad number for alignment
			align.pad( index .. '.', ' ', #indentString ) .. synopsis,
			indent
		) )
	end

	return list
end

-- Specifies how an attribute with types should be formatted
local function formatTypedAttribute( value, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Indents the value name and type
	local typedAttribute = align.left(
		formatSpecial( value.name ) .. ': '
		..  formatAsType( value.type ),
		indent
	) .. '\n\n'
	-- Indents the value description
	.. align.left( value.description, indentString:rep( indentLevel + 1 ) )

	-- Outputs a table's values
	if value.table then
		typedAttribute = typedAttribute .. '\n\n' .. concat( value.table, '\n\n',
		function( _, nestedValue )
			return formatTypedAttribute( nestedValue, indentLevel + 1, indentString )
		end )

	end

	return typedAttribute
end

-- Formats the arguments/returns of a variant
local function getTypedAttributes( variant, attribute, indentLevel, indentString )
	local indent
	indentString, indent = select( 2, getIndentation( indentLevel, indentString ) )

	local typedAttributes = indent .. attribute .. ':\n\n'

	-- Handles formatting for functions that don't have any arguments/returns
	if #( variant[attribute] or {} ) == 0 then
		typedAttributes = typedAttributes .. indentString:rep( indentLevel + 1 ) .. 'None\n'
	else
		typedAttributes = typedAttributes
		-- Separates all of the attributes
		.. concat( variant[attribute], '\n\n', function( _, value )
			return formatTypedAttribute( value, indentLevel + 1, indentString )
		end ) .. '\n'
	end

	return typedAttributes
end

-- Gets the all of a variant's information
local function getFormattedVariant( variant, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Variant description
	return indent .. ( variant.description or 'See function description' ) .. '\n\n'
	-- Variant return values and arguments
	.. getTypedAttributes( variant, 'returns', indentLevel, indentString ) .. '\n'
	.. getTypedAttributes( variant, 'arguments', indentLevel, indentString )
end

-- Formats the contents of all of a function's variants
local function getFormattedVariants( func, fullName, indentLevel, indentString )
	indentLevel, indentString = getIndentation( indentLevel, indentString )

	local formattedSynopses = getFormattedSynopses(
		func, fullName, indentLevel, indentString
	)

	return concat( func.variants, '\n', function( index, variant )
		-- Includes synopsis
		return formattedSynopses[index] .. '\n\n'
		-- ... and the rest of the variant information
		.. getFormattedVariant( variant, indentLevel + 1, indentString )
	end )
end

-- Compiles all of the information about a function
-- Includes details such as the function's description, variants and their parameters, etc.
local function getFunctionOverview( func, parentName, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	local fullName = parentName .. func.name

	-- Tag
	local overview = align.right( formatAsTag( TAG_PREFIX .. fullName ) ) .. '\n'

	-- Name
	.. align.left( formatAsReference( fullName ), indent ) .. '\n\n'

	-- Description
	.. align.left( func.description, indent ) .. '\n\n'

	-- List of synopses
	.. 'Synopses:\n\n'
	.. table.concat( getFormattedSynopses(
		func, fullName, indentLevel + 1, indentString
	), '\n' ) .. '\n\n'

	-- Variants
	.. 'Variants:\n\n'
	.. getFormattedVariants( func, fullName, indentLevel + 1, indentString ) .. '\n'

	return overview
end

-- Lists the functions of a module (or type) in a properly formatted list
local function listModulesFunctions( functions, parentName, funcSeparator, indentLevel, indentString )
	local indent = select( 3, getIndentation( indentLevel, indentString ) )

	return concat( functions, '\n', function( _, func )
		local name = parentName .. funcSeparator .. func.name

		-- Trims name to fit within specified bounds
		local output = align.left( trimFormattedText(
			name,
			TOC_NAME_WIDTH_LIMIT - #indent,
			formatAsReference
		), indent )

		-- Trims tag to fit within specified bounds
		local tag = align.right( trimFormattedText(
			TAG_PREFIX .. name,
			TOC_REF_WIDTH_LIMIT,
			formatAsTag
		), ' ', PAGE_WIDTH - #output )

		return output .. tag
	end )
end
-- }}}

--print( getFunctionOverview( api.functions[1], 'love.' ) )
--print( getFunctionOverview( api.modules[1].functions[8], 'love.audio.' ) )
--print( getFunctionOverview( api.types[1].functions[1], 'Data:' ) )
--print( getFunctionOverview( api.callbacks[1], 'love.' ) )

local indentLevel = 1
print( listModulesFunctions( api.functions, 'love', '.', indentLevel ) )
print( listModulesFunctions( api.modules[3].functions, 'love.filesystem', '.', indentLevel ) )
print( listModulesFunctions( api.types[1].functions, 'Data', ':', indentLevel ) )
print( listModulesFunctions( api.callbacks, 'love', '.', indentLevel ) )

-- Print modeline (spelling/capitalization errors are ugly; use correct file type)
-- (Concat to prevent vim from interpreting THIS as a modeline and messing up synxtax)
print( ' vim' .. ':nospell:ft=help:' )
