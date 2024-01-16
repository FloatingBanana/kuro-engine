local ParserHelper = require "engine.text.parserHelper"

local function insertLine(t, ...)
	for i = 1, select("#",...) do
		t[#t+1] = select(i, ...)
		t[#t+1] = "\n"
	end
end

---@param shaderStr string
---@param defaultDefines table?
---@param isIncludedFile boolean?
---@return string
local function preprocessShader(shaderStr, defaultDefines, isIncludedFile)
	local parser = ParserHelper("", true)
	local lineNumber = 0
	local mainBlock = {}
	local shader = love.filesystem.read(shaderStr) or shaderStr

	-- Add default defines
	for k, v in pairs(defaultDefines or {}) do
		if type(k) == "number" then
			insertLine(mainBlock, ("#define %s"):format(v))
		else
			insertLine(mainBlock, ("#define %s %s"):format(k, v))
		end
	end

	if isIncludedFile then
		local fileGuard = shaderStr:gsub("[^%w]", "_")

		insertLine(
			mainBlock,
			("#ifndef %s"):format(fileGuard),
			("#define %s"):format(fileGuard),
			"#define INCLUDED"
		)
	else
		insertLine(
			mainBlock,
			"#line 0",
			preprocessShader("engine/shaders/default.glsl", {}, true)
		)
	end

	insertLine(mainBlock, "#line 0")

	for line in shader:gmatch("[^\n]+") do
		local result = line

		lineNumber = lineNumber + 1
		parser:reset(line)

		if parser:eat("#") then
			if parser:eat("line") then
				local number = parser:eatMatch(ParserHelper.NumberPattern)
				lineNumber = tonumber(number)
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
					local code = preprocessShader(path, {}, true)

					result = ("#line 0\n%s\n#line %d\n"):format(code, lineNumber)
				end
			end
		end

		-- commit result
		table.insert(mainBlock, result)
	end

	if isIncludedFile then
		insertLine(
			mainBlock,
			"#undef INCLUDED",
			"#endif"
		)
	end

	return table.concat(mainBlock, "\n")
end


return preprocessShader