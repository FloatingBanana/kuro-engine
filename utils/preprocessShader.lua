local Stack = require "engine.collections.stack"

local function isolate_line_number(text, lineNumber)
	return ("\n#line 0\n%s\n#line %d\n"):format(text, lineNumber)
end

local function preprocessShader(shader, defaultDefines)
	local blockStack = Stack()
	local defines = {}
	local lineNumber = 0

	local mainBlock = {isLoop = false}
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

		-- #include feature
		local includePath = line:match("^#%s*pragma include \"(.-)\"")
		if includePath then
			local included = lfs.read("string", includePath)
			assert(included, ("Error on line %d: include file not found"):format(lineNumber))

			-- Resets the line number, then paste the included file contents
			-- to the current line, and after that restore the line count
			result = isolate_line_number(preprocessShader(included, {}), lineNumber)
		end

		local define = line:match("^#%s*define (.*)")
		if define then
			local name, value = define:match("([^%s]*)%s*([^%s]*)")
			defines[name] = value
		end

		-- compile-time for loop
		local loopExpr = line:match("^#%s*pragma for (.*)")
		if loopExpr then
			local var, init, target, step = loopExpr:match("(.-)=([^%s]*),%s*([^%s]*),%s*([^%s]*)%s*$")
			assert(var or init or target or step, "malformed loop expression")

			blockStack:push({
				isLoop = true,
				startLine = lineNumber,
				var = var,
				init = tonumber(init) or defines[init],
				target = tonumber(target) or defines[target],
				step = tonumber(step) or defines[step]
			})

			goto continue
		end

		local isEndLoop = line:match("^#%s*pragma endfor")
		if isEndLoop then
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
			goto continue
		end

		-- commit result
		local block = blockStack:peek()
		table.insert(block, result)

		::continue::
	end

	assert(blockStack:peek() == mainBlock, "missing an '#pragma endfor'")
	return table.concat(mainBlock, "\r\n")
end

return preprocessShader