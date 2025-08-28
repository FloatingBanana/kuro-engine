local ParserHelper = require "engine.text.parserHelper"
local Lume = require "engine.3rdparty.lume"

-- Extremely naive path validation regex
local pathRegex = "^[%w_%-%(%) \\/%.]*$"

---@param shaderStr string
---@param defaultDefines table?
---@param isIncludedFile boolean?
---@return string
local function preprocessShader(shaderStr, defaultDefines, isIncludedFile)
	local parser = ParserHelper("", true)
	local lineNumber = 0
	local mainBlock = {}
	local blockHierarchy = {}
	local shader = shaderStr
	local headerCode = love.filesystem.read("engine/shaders/default.glsl")
	local insertLine = function(...) Lume.push(mainBlock, ...) end

	if shaderStr:match(pathRegex) then
		shader = assert(love.filesystem.read(shaderStr))
	end


	-- Add default defines
	for k, v in pairs(defaultDefines or {}) do
		if v == true then
			insertLine(("#define %s"):format(k))
		elseif type(k) == "number" then
			insertLine(("#define %s"):format(v))
		else
			insertLine(("#define %s %s"):format(k, v))
		end
	end

	if isIncludedFile then
		local fileGuard = shaderStr:gsub("[^%w]", "_")

		-- Setup a file guard to prevent redefinitions
		insertLine(
			("#ifndef %s"):format(fileGuard),
			("#define %s"):format(fileGuard),
			"#define INCLUDED"
		)
	else
		-- Load default header
		insertLine(
			"#line 0",
			headerCode
		)
	end

	-- Reset line number (for error handling)
	insertLine("#line 0")


	-- Begin file processing
	for line in shader:gmatch("[^\n]+") do
		local result = line

		lineNumber = lineNumber + 1
		parser:reset(line)

		-- Handle preprocessor directives
		if parser:eat("#") then
			-- Keep track of explicit line number changes
			if parser:eat("line") then
				local number = parser:eatMatch(ParserHelper.NumberPattern)
				lineNumber = tonumber(number)

			-- Handle special pragma directives
			elseif parser:eat("pragma") then
				-- Special case for love2d shaders, "#pragma language" should be declared at
				-- the very beginning of the file, or else the shader will fail to compile.
				if parser:eat("language") then
					table.insert(mainBlock, 1, result)
					goto continue

				-- Include files
				elseif parser:eat("include") then
					local path = parser:eatMatch("\"(.-)\"")
					local code = preprocessShader(path, {}, true)

					result = ("#line 0\n%s\n#line %d\n"):format(code, lineNumber)

				-- Hacky loop unrolling
				elseif parser:eat("loop") then
					local index = parser:eatMatch(ParserHelper.IdentifierPattern)
					local loopCount = parser:eatMatch(ParserHelper.NumberPattern)

					assert(index and loopCount, "Malformed loop signature")

					table.insert(blockHierarchy, mainBlock)
					mainBlock = {indexName = index, loopCount = math.floor(tonumber(loopCount)), startLine = lineNumber}
					goto continue

				-- End of loop, incremente the index value and copy the loop block for every iteration
				elseif parser:eat("endloop") then
					assert(blockHierarchy[1], "Unmatched endloop directive")

					local block = mainBlock
					mainBlock = table.remove(blockHierarchy)

					for i=0, block.loopCount-1 do
						insertLine(
							"#define "..block.indexName.." "..tostring(i),
							"{",
							"#line "..block.startLine,
							table.concat(block, "\n"),
							"}",
							"#undef "..block.indexName
						)
					end
					result = "#line "..lineNumber
				end
			end
		end

		-- commit result
		insertLine(result)
		::continue::
	end

	assert(not blockHierarchy[1], "Missing #pragma endloop")

	if isIncludedFile then
		-- End file guard
		insertLine(
			"#undef INCLUDED",
			"#endif"
		)
	end

	local code = table.concat(mainBlock, "\n")


	-- Error validation
	local testCode = code
	if isIncludedFile then
		local c = {
			"#pragma language glsl3",
			headerCode,
			code,
			"vec4 effect(EFFECTARGS){return vec4(1);}"
		}

		testCode = table.concat(c, "\n")
	end

	local ok, err = love.graphics.validateShader(false, testCode)
	if not ok then
		local shaderName = shaderStr:gsub("\n.*", "...")
		error(("Failed to validate shader '%s': %s"):format(shaderName, err))
	end

	return code
end


return preprocessShader