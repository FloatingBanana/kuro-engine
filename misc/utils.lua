local Lume = require "engine.3rdparty.lume"


local Utils = {
	preprocessShader = require "engine.misc.preprocessShader",

	fontName = "default",
	fontSize = 13,
	fontcache = {} ---@type love.Font[]
}


---@param shader string
---@param defaultDefines table?
---@return love.Shader
function Utils.newPreProcessedShader(shader, defaultDefines)
	local code = Utils.preprocessShader(shader, defaultDefines)
	local ok, err = love.graphics.validateShader(false, code);
	
	assert(ok, ("Failed to load shader '%s': %s"):format(shader:gsub("\n.*", "..."), err))
	return love.graphics.newShader(code)
end


---@param number any
---@return boolean
function Utils.isNan(number)
	return number ~= number
end


---@param folder string
---@param filter string[]?
---@param recursive boolean
---@param func fun(folder: string, name: string, ext: string)
function Utils.loadFilesFromFolder(folder, filter, recursive, func)
    for i, file in ipairs(love.filesystem.getDirectoryItems(folder)) do
        local name = file:match("^(.*)%.")
        local ext = file:match("%..-$")
        local path = folder.."/"..file

        if recursive and love.filesystem.getInfo(path).type == "directory" then
            Utils.loadFilesFromFolder(path, filter, recursive, func)

        elseif not filter or Lume.find(filter, ext) then
            func(folder, name, ext)
        end
    end
end


---@param startFolder string
---@param recursive boolean
---@param results table<string, any>
function Utils.requireFilesFromFolder(startFolder, recursive, results)
    Utils.loadFilesFromFolder(startFolder, {".lua"}, recursive, function(folder, name, ext)
		local result = require(folder.."."..name)

		if results then
			results[name] = result
		end
	end)
end


---@param filename string
---@param size number
---@overload fun(size: number)
function Utils.setFont(filename, size)
	if not size then
		---@diagnostic disable-next-line cast-local-type
		filename, size = "default", filename or 13
	end

	local fonts = Utils.fontcache
	local name = filename..size
	

	-- Cache font object
	if not fonts[name] then
		if filename == "default" then
			fonts[name] = love.graphics.newFont(size)
		else
			fonts[name] = love.graphics.newFont(filename, size)
		end
	end

	love.graphics.setFont(fonts[name])
	Utils.fontName = filename
	Utils.fontSize = size
end


---@return love.Font
function Utils.getCurrentFont()
	return Utils.fontcache[Utils.fontName..Utils.fontSize]
end

Utils.dummySquare = love.graphics.newMesh({
	{0,0,0,0},
	{1,0,1,0},
	{0,1,0,1},
	{1,1,1,1}
}, "strip", "static")


---@param size Vector2
---@return love.Mesh
function Utils.newSquareMesh(size)
	local w, h = size.width, size.height
	return love.graphics.newMesh({
        {0,0,0,0},
        {w,0,1,0},
        {0,h,0,1},
        {w,h,1,1}
    }, "strip", "static")
end


return Utils