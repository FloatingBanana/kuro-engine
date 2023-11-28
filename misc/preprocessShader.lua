local Stack = require "engine.collections.stack"
local ParserHelper = require "engine.text.parserHelper"

local function isolate_line_number(text, lineNumber)
	return ("\n#line 0\n%s\n#line %d\n"):format(text, lineNumber)
end


---@param shader string
---@param defaultDefines table?
---@return string
local function preprocessShader(shader, defaultDefines)
	local blockStack = Stack()
	local parser = ParserHelper("", true)
	local defines = {}
	local lineNumber = 0

	local file, err = love.filesystem.read(shader)
	if file then
		shader = file
	end

	local mainBlock = {}
	blockStack:push(mainBlock)

	-- Add default defines
	for k, v in pairs(defaultDefines or {}) do
		if type(k) == "number" then
			table.insert(mainBlock, ("#define %s\n"):format(v))
		else
			table.insert(mainBlock, ("#define %s %s\n"):format(k, v))
		end

		table.insert(mainBlock, "#line 0\n")
	end

	for line in shader:gmatch("[^\n]+") do
		local result = line

		lineNumber = lineNumber + 1
		parser:reset(line)

		if parser:eat("#") then
			-- Store defines
			if parser:eat("define") then
				local name = parser:eatMatch(ParserHelper.IdentifierPattern)
				local value = parser:eatMatch(ParserHelper.IdentifierPattern)

				defines[name] = value or true
			end

			-- Delete defines
			if parser:eat("undef") then
				local name = parser:eatMatch(ParserHelper.IdentifierPattern)
				defines[name] = nil
			end

			-- Handle special pragma directives
			if parser:eat("pragma") then
				-- Special case for love2d shaders, "#pragma language" should be declared at
				-- the very beginning of the file, or else the shader will fail to compile.
				if parser:eat("language") then
					table.insert(mainBlock, 1, result)
					result = ""
				end

				-- Include files
				if parser:eat("include") then
					local path = parser:eatMatch("\".-\""):sub(2, -2)
					local included = love.filesystem.read("string", path)

					result = isolate_line_number(preprocessShader(included, {}), lineNumber)
				end

				-- Compile time for loop
				if parser:eat("for") then
					local var = parser:eatMatch(ParserHelper.IdentifierPattern)
					assert(parser:eat("="))
					local init = parser:eatMatch(ParserHelper.IdentifierPattern)
					assert(parser:eat(","))
					local target = parser:eatMatch(ParserHelper.IdentifierPattern)
					assert(parser:eat(","))
					local step = parser:eatMatch(ParserHelper.IdentifierPattern)

					blockStack:push({
						startLine = lineNumber,
						var = var,
						init = tonumber(init) or defines[init],
						target = tonumber(target) or defines[target],
						step = tonumber(step) or defines[step]
					})
				end

				-- End for loop block
				if parser:eat("endfor") then
					local thisBlock = blockStack:pop()
					local currBlock = blockStack:peek()
					local startLine = thisBlock.startLine
					local endLine = lineNumber
					local blockCode = table.concat(thisBlock, "\r\n")

					for i = thisBlock.init, thisBlock.target-1, thisBlock.step do
						local code =
							"#undef %s\n"..
							"#define %s %d\n" ..
							"#line %d\n" ..
							blockCode ..
							"\n"

						table.insert(currBlock, code:format(thisBlock.var, thisBlock.var, i, startLine))
					end

					local endCode =
						"#undef %s\n" ..
						"#line %d"

					table.insert(currBlock, endCode:format(thisBlock.var, endLine))
				end
			end
		end

		-- commit result
		local block = blockStack:peek()
		table.insert(block, result)
	end

	assert(blockStack:peek() == mainBlock, "missing an '#pragma endfor'")
	return table.concat(mainBlock, "\r\n")
end


return preprocessShader