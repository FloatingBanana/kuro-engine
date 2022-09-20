local Utils = {}

function Utils.isNan(number)
	return number ~= number
end

function Utils.loadFilesFromFolder(folder, filter, recursive, func)
    for i, file in ipairs(lfs.getDirectoryItems(folder)) do
        local name = file:match("^(.*)%.")
        local ext = file:match("%..-$")
        local path = folder.."/"..file

        if recursive and lfs.getInfo(path).type == "directory" then
            Utils.loadFilesFromFolder(path, filter, recursive, func)

        elseif not filter or Lume.find(filter, ext) then
            func(folder, name, ext)
        end
    end
end

function Utils.requireFilesFromFolder(startFolder, recursive, results)
    Utils.loadFilesFromFolder(startFolder, {".lua"}, recursive, function(folder, name, ext)
		local result = require(folder.."."..name)

		if results then
			results[name] = result
		end
	end)
end

local fonts = {}
local currFont = "default13"
function Utils.setFont(name, size)
	if not size then
		name, size = "default", name or 13
	end

	local filename = name..size

	if not fonts[filename] then
		if name == "default" then
			fonts[filename] = lg.newFont(size)
		else
			if lfs.getInfo("assets/fonts/"..name..".otf") then
				fonts[filename] = lg.newFont("assets/fonts/"..name..".otf", size)
			else
				fonts[filename] = lg.newFont("assets/fonts/"..name..".ttf", size)
			end
		end
	end

	lg.setFont(fonts[filename])
	currFont = filename
end




local function preprocessShader(shader, defines)
	local processed = {}
	local lineNumber = 0

	-- Add default defines
	for k, v in pairs(defines) do
		if type(k) == "number" then
			table.insert(processed, ("#define %s\n"):format(v))
		else
			table.insert(processed, ("#define %s %s\n"):format(k, v))
		end

		table.insert(processed, "#line 0\n")
	end

	-- Iterate through every line
	for line in shader:gmatch("(.-)[\n$]") do
		local result = line
		lineNumber = lineNumber + 1

		-- Match line that starts with #pragma include "filename"
		local includePath = line:match("^#%s*pragma include \"(.-)\"")
		if includePath then
			-- Try reading the included file
			local included = lfs.read("string", includePath)
			assert(included, ("Error on line %d: include file not found"):format(lineNumber))

			-- Resets the line number, then paste the included file contents
			-- to the current line, and after that restore the line count
			result = ("\n#line 0\n%s\n#line %d\n"):format(preprocessShader(included, {}), lineNumber)
		end

		table.insert(processed, result)
	end

	return table.concat(processed)
end

function Utils.newPreprocessedShader(fragmentShader, vertexShader, defines)
	local processedFragmentShader = nil
	local processedVertexShader = nil

	-- Read the file if the string is a file path
	if lfs.getInfo(fragmentShader, "file") then
		fragmentShader = lfs.read("string", fragmentShader)
	end
	processedFragmentShader = preprocessShader(fragmentShader, defines)

	-- Vertex shader is optional
	if vertexShader then
		if lfs.getInfo(vertexShader, "file") then
			vertexShader = lfs.read("string", vertexShader)
		end

		processedVertexShader = preprocessShader(vertexShader, defines)
	end

	return lg.newShader(processedFragmentShader, processedVertexShader)
end

return Utils