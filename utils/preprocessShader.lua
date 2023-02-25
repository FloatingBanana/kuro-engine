local Stack = require "engine.collections.stack"
local ParserHelper = require "engine.misc.parserHelper"

local function isolate_line_number(text, lineNumber)
	return ("\n#line 0\n%s\n#line %d\n"):format(text, lineNumber)
end

local function preprocessShader(shader, defaultDefines)
	local blockStack = Stack()
	local parser = ParserHelper()
	local defines = {}
	local lineNumber = 0

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

	for line in shader:gmatch("[^\r\n]+") do
		local result = line

		lineNumber = lineNumber + 1
		parser:reset(line)

		if parser:eat("#", true) then
			-- Store defines
			if parser:eat("define", true) then
				local name = parser:eatMatch(ParserHelper.identifierPattern, true)
				local value = parser:eatMatch(ParserHelper.identifierPattern, true)

				defines[name] = value or true
			end

			-- Delete defines
			if parser:eat("undef", true) then
				local name = parser:eatMatch(ParserHelper.identifierPattern, true)
				defines[name] = nil
			end

			-- Handle special pragma directives
			if parser:eat("pragma", true) then
				-- Include files
				if parser:eat("include", true) then
					local path = parser:eatMatch("\".-\"", true):sub(2, -2)
					local included = lfs.read("string", path)

					result = isolate_line_number(preprocessShader(included, {}), lineNumber)
				end

				-- Compile time for loop
				if parser:eat("for", true) then
					local var = parser:eatMatch(ParserHelper.identifierPattern, true)
					assert(parser:eat("=", true))
					local init = parser:eatMatch(ParserHelper.identifierPattern, true)
					assert(parser:eat(",", true))
					local target = parser:eatMatch(ParserHelper.identifierPattern, true)
					assert(parser:eat(",", true))
					local step = parser:eatMatch(ParserHelper.identifierPattern, true)

					blockStack:push({
						startLine = lineNumber,
						var = var,
						init = tonumber(init) or defines[init],
						target = tonumber(target) or defines[target],
						step = tonumber(step) or defines[step]
					})
				end

				-- End for loop block
				if parser:eat("endfor", true) then
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