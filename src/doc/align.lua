-- Align monospaced text

-- Variables that control the output
local defaultWidth = 79
local tabWidth = 8
local tabStr = (' '):rep( tabWidth )

-- Change the global defaultWidth
local function setDefaultWidth( n )
	defaultWidth = n
end

-- Change the global tabWidth
local function setTabWidth( n )
	tabWidth = n
end

-- Set the tab string
local function setTabStr( str )
	tabStr = str
end

-- Add a new line
local function newLine( currentLine, fill, textWidth, determineSpacing )
	local returnString = ''

	-- Ignore blank lines/lines that consist solely of whitespace
	if #currentLine > 0 then
		returnString = fill:rep( determineSpacing( currentLine, textWidth ) ) .. currentLine
	end

	return returnString .. '\n'
end

-- Determine the number of spaces required to right-align currentLine
local function determineRightAlignSpacing( currentLine, textWidth )
	return textWidth - #currentLine
end

-- Loop over words (separated by spaces)
-- Add space to beginning of line (instead of end) to make linebreaks easier to determine
local function loopOverTextByWord( line, fill, textWidth, spacingFunc )
	-- Loop over words (separated by spaces)
	-- Add space to beginning of line (instead of end) to make linebreaks easier to determine
	line = ' ' .. line

	-- Used to trim the space added to the beginning of the line
	local first = true

	-- Current line is the line on which the function is currently working
	-- output is the string returned by the function
	local currentLine, output = '', ''

	line:gsub( '(%s+)(%S+)', function( spacing, word )
		-- Trim the space
		if first then
			spacing = spacing:match( '^%s(.*)$' )
			first = false
		end

		if #currentLine + #spacing + #word <= textWidth then
			-- Word is short enough
			currentLine = currentLine .. spacing .. word
		else
			-- Line needs to be wrapped
			if #currentLine == 0 then
				-- If currentLine is blank and it's too long, hyphenate it
				while #word > textWidth do
					currentLine = word:sub( 1, textWidth - 1 ) .. '-'
					output = output .. newLine( currentLine, fill, textWidth, spacingFunc )
					word = word:sub( textWidth )
				end
			else
				-- word is short enough to not be hyphenated
				output = output .. newLine( currentLine, fill, textWidth, spacingFunc )
			end

			-- Update the current line
			currentLine = word
		end
	end )

	-- Add any non-wrapped content to the output and return it
	output = output .. newLine( currentLine, fill, textWidth, spacingFunc )
	return output
end

-- Loop over the string by lines to respect new lines
local function loopOverTextByLine( text, fill, textWidth, spacingFunc )
	-- Add a new line to text to handle all cases (removed later)
	text = text .. '\n'

	local output = ''
	text:gsub( '(.-)\n', function( line )
		output = output .. loopOverTextByWord( line, fill, textWidth, spacingFunc )
	end )

	-- Trim the last new line, which was only added for easier looping
	return output:match( '^(.-)\n$' )
end

-- Right-align text to a given width

-- TODO: allow multi-character fill
-- fill is what to use to pad the width of the text (must be one character)
local function alignRight( text, fill, textWidth )
	fill = fill or ' '
	textWidth = textWidth or defaultWidth

	return loopOverTextByLine( text, fill, textWidth, determineRightAlignSpacing )
end

-- left-align text to a given width
local function alignLeft( text, indentStr, textWidth, doNotIndentFirstLine )
	indentStr = indentStr or ''
	doNotIndentFirstLine = doNotIndentFirstLine or false

	-- Account for indentStr in text wrapping
	textWidth = ( textWidth or defaultWidth ) - #indentStr

	return loopOverTextByLine( text, indentStr, textWidth, function()
		local result = doNotIndentFirstLine and 0 or 1
		doNotIndentFirstLine = false
		return result
	end )
end

-- Pad text
-- fill is the character (or series of characters) that should pad the text to the desired with
local function alignPad( text, fill, width )
	fill = fill or ' '
	width = width or defaultWidth

	-- Cut text if it's too long
	if #text >= width then
		text = text:sub( 1, width - 1 ) .. '-'
	end

	return ( text .. fill:rep( math.ceil( width - #text / #fill ) ) ):sub( 1, width )
end

return {
	setDefaultWidth = setDefaultWidth,
	setTabWidth = setTabWidth,
	setTabStr = setTabStr,
	right = alignRight,
	left = alignLeft,
	pad = alignPad,
}
