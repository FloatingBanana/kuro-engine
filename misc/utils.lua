local Lume   = require "engine.3rdparty.lume"
local Object = require "engine.3rdparty.classic.classic"
local ffi    = require "ffi"


local Utils = {
	preprocessShader = require "engine.misc.preprocessShader",

	fontName = "default",
	fontSize = 13,
	fontcache = {}, ---@type love.Font[]

	shaderCache = {} ---@type table<string, table<table, love.Shader>>
}


function Utils.combineShaders(vert, frag)
	vert = love.filesystem.read(vert) or vert
	frag = love.filesystem.read(frag) or frag

	return string.format("#ifdef VERTEX\n#line 0\n%s\n#endif\n#ifdef PIXEL\n#line 0\n%s\n#endif", vert, frag)
end


---@param shader love.Shader
---@param uniform string
---@param ... any
---@return boolean
function Utils.trySendUniform(shader, uniform, ...)
	if shader:hasUniform(uniform) then
		shader:send(uniform, ...)
		return true
	end
	return false
end


---@param shaderStr string
---@param defaultDefines table?
---@return love.Shader
function Utils.newPreProcessedShader(shaderStr, defaultDefines)
	return love.graphics.newShader(Utils.preprocessShader(shaderStr, defaultDefines, false))
end


---@param shaderStr string
---@param defaultDefines table?
---@return love.Shader
function Utils.newPreProcessedShaderCache(shaderStr, defaultDefines)
	defaultDefines = defaultDefines or {}
	local shader = Utils.getCachedShader(shaderStr, defaultDefines)

	if not shader then
		shader = Utils.newPreProcessedShader(shaderStr, defaultDefines)
		Utils.cacheShader(shaderStr, defaultDefines, shader)
	end

	return shader
end


---@param shaderStr string
---@param defines table
---@param shader love.Shader
function Utils.cacheShader(shaderStr, defines, shader)
	local cache = Utils.shaderCache

	cache[shaderStr] = cache[shaderStr] or {}
	cache[shaderStr][defines] = shader
end


---@param shaderStr string
---@param defines table
---@return love.Shader?
function Utils.getCachedShader(shaderStr, defines)
	local cache = Utils.shaderCache

	if cache[shaderStr] then
		for cacheDefs, shader in pairs(cache[shaderStr]) do
			if Utils.isTableEqual(cacheDefs, defines, true) then
				return shader
			end
		end
	end

	return nil
end


---@param t1 table
---@param t2 table
---@param ignoreArrayOrder boolean
---@return boolean
function Utils.containsTable(t1, t2, ignoreArrayOrder)
	for k, v in pairs(t2) do
		if ignoreArrayOrder and type(k) == "number" and not Lume.find(t1, v) then
			return false
		elseif t1[k] ~= v then
    	    return false
    	end
	end
	return true
end


---@param v any
---@return string|ffi.ctype*|Object
function Utils.getType(v)
	if type(v) == "table" and v.is and v:is(Object) then
		return getmetatable(v)
	elseif type(v) == "table" and v.typename then
		return v.typename
	elseif type(v) == "cdata" then
		return ffi.typeof(v)
	else
		return type(v)
	end
end



local function copyTable(t, refs)
	local result = {}
	refs[t] = result

	for key, value in pairs(t) do
		local nkey   = refs[key]   or type(key)   == "table" and copyTable(key, refs)   or key
		local nvalue = refs[value] or type(value) == "table" and copyTable(value, refs) or value

		refs[key] = nkey
		refs[value] = nvalue

		result[nkey] = nvalue
	end

	return result
end

---@param t table
---@return table
function Utils.deepCopy(t)
	return setmetatable(copyTable(t, {}), getmetatable(t))
end


---@param t1 table
---@param t2 table
---@param ignoreArrayOrder boolean
---@return boolean
function Utils.isTableEqual(t1, t2, ignoreArrayOrder)
	return Utils.containsTable(t1, t2, ignoreArrayOrder) and Utils.containsTable(t2, t1, ignoreArrayOrder)
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