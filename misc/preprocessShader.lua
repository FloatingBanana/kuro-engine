local ParserHelper = require "engine.text.parserHelper"

---@param shader string
---@param defaultDefines table?
---@param isIncludedFile boolean?
---@return string
local function preprocessShader(shader, defaultDefines, isIncludedFile)
	local parser = ParserHelper("", true)
	local lineNumber = 0
	local mainBlock = {}
	shader = love.filesystem.read(shader) or shader


	-- Add default defines
	for k, v in pairs(defaultDefines or {}) do
		if type(k) == "number" then
			table.insert(mainBlock, ("#define %s\n"):format(v))
		else
			table.insert(mainBlock, ("#define %s %s\n"):format(k, v))
		end
	end

	if isIncludedFile then
		table.insert(mainBlock, "#define INCLUDED\n")
	else
		table.insert(mainBlock, "#line 0\n")
		table.insert(mainBlock, preprocessShader("engine/shaders/default.glsl", {}, true))
	end

	table.insert(mainBlock, "#line 0\n")

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
					local included = love.filesystem.read("string", path)
					local code = preprocessShader(included, {}, true)

					result = ("#line 0\n%s\n#line %d\n"):format(code, lineNumber)
				end
			end
		end

		-- commit result
		table.insert(mainBlock, result)
	end

	if isIncludedFile then
		table.insert(mainBlock, "#undef INCLUDED")
	end

	return table.concat(mainBlock, "\r\n")
end


return preprocessShader