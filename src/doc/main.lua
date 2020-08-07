local api = require( 'love-api.love_api' )
local align = require( 'align' )

-- Local variables {{{
local INDENT_STRING = '    '
local TAG_PREFIX = 'love-'

local PAGE_WIDTH = 79
align.setDefaultWidth( PAGE_WIDTH )

local TOC_NAME_WIDTH_LIMIT = 40
local TOC_NAME_REF_SPACING = 2
local TOC_REF_WIDTH_LIMIT = PAGE_WIDTH - TOC_NAME_WIDTH_LIMIT - TOC_NAME_REF_SPACING

local LOVE_TYPES = {}

local LUA_TYPES = {
	['boolean']        = '|lrv-boolean|',
	['function']       = '|lrv-function|',
	['nil']            = '|lrv-nil|',
	['number']         = '|lrv-number|',
	['string']         = '|lrv-string|',
	['table']          = '|lrv-table|',
	['thread']         = '|lrv-thread|',
	['userdata']       = '|lrv-userdata|',
	['light userdata'] = '|lrv-lightuserdata|',
}
-- }}}

-- Misc. functions {{{
local function getIndentation( indentLevel, indentString, defaultIndentLevel )
	indentLevel = indentLevel or defaultIndentLevel or 0
	indentString = indentString or INDENT_STRING
	local indent = indentString:rep( indentLevel )

	return indentLevel, indentString, indent
end

local function getLoveTypes( tab )
	for _, attribute in ipairs{ 'enums', 'types' } do
		for _, t in ipairs( tab[attribute] or {} ) do
			LOVE_TYPES[t.name] = true
		end
	end
end
-- }}}

-- Formatting functions {{{
local function section()
	return ('='):rep( PAGE_WIDTH )
end

local function subsection()
	return ('-'):rep( PAGE_WIDTH )
end

local function formatAsTag( str )
	return ('*%s*'):format( str )
end

local function formatAsReference( str )
	return ('|%s|'):format( str )
end

-- Formats arguments and return values
-- I'm not actually sure if there's a specific name for this formatting
local function formatSpecial( str )
	return ('`%s`'):format( str )
end

local function formatAsType( str )
	if LOVE_TYPES[str] then
		return ('|love-%s|'):format( str )
	elseif LUA_TYPES[str] then
		return LUA_TYPES[str]
	else
		return ('<%s>'):format( str )
	end
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

-- Trims text that is surrounded by formatting without removing the formatting
-- `ThisIsTooLong` -> `ThisIs-` if with = 7
local function trimFormattedText( str, width, formatFunc )
	local formattedStr = formatFunc( str )

	-- Allows for the formatting func perform differently based on #str
	while #formattedStr > width do
		str = str:sub( 1, -2 )
		formattedStr = formatFunc( str .. '-' )
	end

	return formattedStr
end

-- Prints a table of contents of `tab` in the format:
--
--	attributeName              tagPrefix .. attributeName
--
-- Where `attributeName` is either `tab[i].name` or `tab[i]`
-- `attributeName` is trimmed to be within `TOC_NAME_WIDTH_LIMIT` (including indent)
-- The tag is also trimmed, to the width of `TOC_REF_WIDTH_LIMIT`
local function printTableOfContents( tab, tagPrefix, indentLevel, indentString )
	local indent = select( 3, getIndentation( indentLevel, indentString ) )
	tab = tab or {}

	if #tab == 0 then
		return indent .. 'None'
	else
		return concat( tab, '\n', function( _, attr )
			local attrName = attr.name or tostring( attr )

			-- Trims name
			local name = align.left( trimFormattedText(
				attrName,
				TOC_NAME_WIDTH_LIMIT - #indent,
				formatAsReference
			), indent )

			-- Trims tag
			local trimmedTag = trimFormattedText(
				tagPrefix .. attrName,
				TOC_REF_WIDTH_LIMIT,
				formatAsReference
			)

			-- Left-aligns tag
			local width = TOC_NAME_WIDTH_LIMIT - #name + TOC_NAME_REF_SPACING
			local spacing = (' '):rep( width )

			return name .. spacing .. trimmedTag
		end )
	end
end

-- Handles the most basic and common case of a table of contents, with a basic
-- tag and description
local function printTOCWithTagAndDesc( tab, attribute, tagPrefix, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Tag
	return align.right( formatAsTag( TAG_PREFIX .. tab.name .. '-' .. attribute ) ) .. '\n'
	-- Basic identifier
	.. align.left( attribute .. ':', indent ) .. '\n\n'
	-- Table of contents
	.. printTableOfContents( tab[attribute], TAG_PREFIX .. tagPrefix, indentLevel + 1, indentString )
end

-- Gets a *very* basic (aligned/indented) description
local function getBasicDescription( attribute, moduleName, indent )
	indent = indent or ''
	return align.left(
		'The ' .. attribute .. ' of ' .. formatAsReference( moduleName ) .. ':',
		indent
	)
end
-- }}}

-- Functions {{{
-- Gets a synopsis of a function variant
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

-- Assembles a list of a function's synopses as a table
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
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	local list = {}

	local synopses = getSynopses( func, fullName )
	for index, synopsis in ipairs( synopses ) do
		-- `align.left` accounts for synopses that could span multiple lines
		table.insert( list, align.left(
			-- Pads reference number for alignment purposes
			indent .. align.pad( index .. '.', ' ', #indentString ) .. synopsis,
			indentString:rep( indentLevel + 1 ),
			-- Use default text width; do not indent first line
			nil, true
		) )
	end

	return list
end

-- Specifies how an attribute with types should be formatted
-- An attribute can be a parameter or return value
-- Specifically, this outputs the name, description, in-depth argument and return
-- value descriptions, etc.
local function formatTypedAttribute( value, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Indents the value name and type
	local typedAttribute = align.left(
		formatSpecial( value.name ) .. ': ' .. formatAsType( value.type ),
		indent
	) .. '\n\n'
	-- Indents the value description
	.. align.left( value.description, indentString:rep( indentLevel + 1 ) )

	-- Outputs a table's values (if applicable)
	if value.table then
		typedAttribute = typedAttribute .. '\n\n'
		.. concat( value.table, '\n\n', function( _, nestedValue )
			return formatTypedAttribute( nestedValue, indentLevel + 1, indentString )
		end )
	end

	return typedAttribute
end

-- Formats the arguments/return values of a function variant
local function getTypedAttributes( variant, attribute, indentLevel, indentString )
	local indent
	indentString, indent = select( 2, getIndentation( indentLevel, indentString ) )

	-- Begins the typedAttributes information
	local typedAttributes = indent .. attribute .. ':\n\n'

	-- Handles formatting for functions that don't have any arguments/returns
	if #( variant[attribute] or {} ) == 0 then
		typedAttributes = typedAttributes .. indentString:rep( indentLevel + 1 ) .. 'None'
	else
		typedAttributes = typedAttributes
		-- Separates all of the attributes
		.. concat( variant[attribute], '\n\n', function( _, attr )
			return formatTypedAttribute( attr, indentLevel + 1, indentString )
		end )
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
	.. getTypedAttributes( variant, 'returns', indentLevel, indentString ) .. '\n\n'
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
	.. indent .. 'Synopses:\n\n'
	.. table.concat( getFormattedSynopses(
		func, fullName, indentLevel + 1, indentString
	), '\n' ) .. '\n\n'

	-- Variants
	.. indent .. 'Variants:\n\n'
	.. getFormattedVariants( func, fullName, indentLevel + 1, indentString )

	return overview
end

-- Lists the functions of a module (or type) in a properly formatted list
local function listModulesFunctions( functions, functionPrefix, indentLevel, indentString )
	return printTableOfContents( functions, TAG_PREFIX .. functionPrefix, indentLevel, indentString )
end

-- Gets a module's formatted functions (descriptions, parameters, return values, etc.)
local function getFormattedModuleFunctions( tab, functionPrefix, indentLevel, indentString )
	indentLevel, indentString = getIndentation( indentLevel, indentString )

	return concat( tab, '\n\n', function( _, func )
		return subsection() .. '\n'
		.. getFunctionOverview( func, functionPrefix, indentLevel, indentString )
	end )
end

-- Shows all of the functions of a module, then gives the formatted functions
-- `attribute` is either 'callbacks' or 'functions'
local function compileFormattedModuleFunctions(
		module, attribute,
		parentName, funcSeparator,
		indentLevel, indentString
	)
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	local functionPrefix = parentName .. funcSeparator
	module[attribute] = module[attribute] or {}

	local formattedModuleFunctions = subsection() .. '\n'

	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. parentName .. '-' .. attribute ) ) .. '\n'
	-- Description
	.. getBasicDescription( attribute, parentName, indent ) .. '\n\n'
	-- List of functions
	.. listModulesFunctions(
		module[attribute], parentName .. funcSeparator,
		indentLevel + 1, indentString
	) .. '\n'

	-- Handles modules without any callbacks/functions
	if #module[attribute] == 0 then
		return formattedModuleFunctions
	else
		-- Gets the formatted functions
		return formattedModuleFunctions .. '\n' .. getFormattedModuleFunctions(
			module[attribute], functionPrefix, indentLevel, indentString
		)
	end
end
-- }}}

-- Types {{{
-- Gets all of a type's information (constructors, supertypes, subtypes, etc.)
-- Also includes its description and tag
local function getFormattedType( Type, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Handles Types without functions
	Type.functions = Type.functions or {}
	local typePrefix = Type.name .. ':'

	local formattedType = subsection() .. '\n'
	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. Type.name ) ) .. '\n'
	-- Basic identifier
	.. align.left( formatAsReference( Type.name ) ) .. '\n\n'
	-- Description
	.. align.left( Type.description, indent ) .. '\n\n'

	-- Constructors
	.. printTOCWithTagAndDesc( Type, 'constructors', '', indentLevel + 1, indentString ) .. '\n\n'
	-- Supertypes
	.. printTOCWithTagAndDesc( Type, 'supertypes', '', indentLevel + 1, indentString ) .. '\n\n'
	-- Subtypes
	.. printTOCWithTagAndDesc( Type, 'subtypes', '', indentLevel + 1, indentString ) .. '\n\n'
	-- Functions (TOC)
	.. printTOCWithTagAndDesc( Type, 'functions', typePrefix, indentLevel + 1, indentString )

	-- Gets type's functions (if any)
	if #Type.functions == 0 then
		return formattedType
	else
		return formattedType .. '\n\n' .. getFormattedModuleFunctions(
			Type.functions,
			typePrefix,
			indentLevel, indentString
		)
	end
end

-- Combines all of a module's formatted types
local function getFormattedTypes( types, indentLevel, indentString )
	return concat( types, '\n\n', function( _, Type )
		return getFormattedType( Type, indentLevel, indentString )
	end )
end

-- Lists the types of a module in a properly formatted list
local function listModulesTypes( types, indentLevel, indentString )
	return printTableOfContents( types, TAG_PREFIX, indentLevel, indentString )
end

-- Shows all the formatted types of a module, then gets the formatted the types
-- Also includes a basic description and tag
local function compileFormattedModuleTypes( module, parentName, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	module.types = module.types or {}

	local formattedModuleTypes = subsection() .. '\n'
	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. parentName .. '-types' ) ) .. '\n'
	-- Description
	.. getBasicDescription( 'types', parentName, indent ) .. '\n\n'
	-- List of types
	.. listModulesTypes( module.types, indentLevel + 1, indentString )

	-- Gets the formatted types
	if #module.types == 0 then
		return formattedModuleTypes
	else
		return formattedModuleTypes .. '\n\n'
		.. getFormattedTypes( module.types, indentLevel, indentString )
	end
end
-- }}}

-- Enums {{{
-- Gets all of an enum's information
-- Also includes its tag, description, etc.
local function getFormattedEnum( enum, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	-- Adds a type to all constants to work with getTypedAttributes
	for i in ipairs( enum.constants ) do
		enum.constants[i].type = 'string'
	end

	return subsection() .. '\n'
	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. enum.name ) ) .. '\n'
	-- Basic identifier
	.. align.left( formatAsReference( enum.name ) ) .. '\n\n'
	-- Description
	.. align.left( enum.description, indent ) .. '\n\n'
	-- Gets the constants of the enum
	.. getTypedAttributes( enum, 'constants', indentLevel + 1, indentString )
end

-- Combines all of a module's formatted enums
local function getFormattedEnums( enums, indentLevel, indentString )
	return concat( enums, '\n\n', function( _, enum )
		return getFormattedEnum( enum, indentLevel, indentString )
	end )
end

-- Lists the enums of a module in a properly formatted list
local function listModulesEnums( enums, indentLevel, indentString )
	return printTableOfContents( enums, TAG_PREFIX, indentLevel, indentString )
end

-- Assembles all of a module's enums and information, including enums' constants, etc.
local function compileFormattedModuleEnums( module, parentName, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	module.enums = module.enums or {}

	local formattedEnums = subsection() .. '\n'
	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. parentName .. '-enums' ) ) .. '\n'
	-- Basic identifier
	.. getBasicDescription( 'enums', parentName, indent ) .. '\n\n'
	-- List of enums
	.. listModulesEnums( module.enums, indentLevel + 1, indentString ) .. '\n'

	-- Gets the formatted enums (if applicable)
	if #module.enums == 0 then
		return formattedEnums
	else
		return formattedEnums .. '\n'
		.. getFormattedEnums( module.enums, indentLevel, indentString ) .. '\n'
	end
end
-- }}}

-- Output {{{
-- Combines all of a module's information
local function compileModuleInformation( module, namePrefix, indentLevel, indentString )
	local indent
	indentLevel, indentString, indent = getIndentation( indentLevel, indentString )

	local fullName = namePrefix .. module.name

	return  section() .. '\n'
	-- Tag
	.. align.right( formatAsTag( TAG_PREFIX .. fullName ) ) .. '\n'

	-- Name and description
	.. align.left( formatAsReference( fullName ) ) .. '\n\n'
	.. align.left( module.description, indent ) .. '\n\n'

	-- Table of contents
	.. printTableOfContents(
		{ 'callbacks', 'enums', 'functions', 'types' },
		TAG_PREFIX .. fullName .. '-', indentLevel + 1, indentString
	) .. '\n\n'

	-- Callbacks
	.. compileFormattedModuleFunctions(
		module, 'callbacks',
		fullName, '.',
		indentLevel, indentString
	) .. '\n'

	-- Enums
	.. compileFormattedModuleEnums( module, fullName, indentLevel, indentString ) .. '\n'

	-- Functions
	.. compileFormattedModuleFunctions(
		module, 'functions',
		fullName, '.',
		indentLevel, indentString
	) .. '\n'

	-- Types
	.. compileFormattedModuleTypes( module, fullName, indentLevel, indentString ) .. '\n'
end

-- Header {{{
print( ( [[
*love.txt* *love2d*                 Documentation for the LOVE game framework.

                        _       o__o __      __ ______ ~
                       | |     / __ \\ \    / //  ____\~
                       | |    | |  | |\ \  / / | |__   ~
                       | |    | |  | | \ \/ /  |  __|  ~
                       | |____| |__| |  \  /   | |____ ~
                       \______|\____/    \/    \______/~

                   The complete solution for Vim with LOVE.
                   Includes highlighting and documentation.

For LOVE (http://love2d.org) version %s.

Generated from

    https://github.com/love2d-community/love-api

using

    https://github.com/davisdude/vim-love-docs

Made by Davis Claiborne under the MIT license. See LICENSE.md for more info.
]] ):format( api.version ) )
-- }}}

-- Gets table information to know how to format types
getLoveTypes( api )
for _, module in ipairs( api.modules ) do
	getLoveTypes( module )
end

-- Gives the love module basic information
api.name = 'love'
api.description = 'The LÖVE framework'
print( compileModuleInformation( api, '' ) )

for _, module in ipairs( api.modules ) do
	print( compileModuleInformation( module, 'love.' ) )
end

-- Prints modeline (spelling/capitalization errors are ugly; use correct file type)
-- (Uses concat to prevent vim from interpreting THIS as a modeline)
print( ' vim' .. ':nospell:ft=help:' )
-- }}}
