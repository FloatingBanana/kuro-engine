local Lume   = require "engine.3rdparty.lume"
local Object = require "engine.3rdparty.classic.classic"
local Kuro   = require "engine.kuro"
local ffi    = require "ffi"


local Utils = {
	preprocessShader = require "engine.misc.preprocessShader",

	fontName = "default",
	fontSize = 13,
	fontcache = {}, ---@type love.Font[]
}


---@param vert string
---@param frag string
---@return string
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
	local code = Utils.preprocessShader(shaderStr, defaultDefines)
	local shader = love.graphics.newShader(code)
	local warnings = shader:getWarnings()

	if warnings ~= "vertex shader:\npixel shader:\n" then
		local shadername = shaderStr:gsub("\n.*", "...")
		print(("Warnings at shader '%s':\n%s"):format(shadername, warnings))
	end

	return shader
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


---@param t table
---@param item any
---@return integer?
function Utils.findIndex(t, item)
	for i=1, #t do
		if t[i] == item then
			return i
		end
	end
	return nil
end


function Utils.push(t, ...)
	local tsize = #t
	for i=1, select("#", ...) do
		t[tsize + i] = select(i, ...)
	end
end


---@param v any
---@return string|ffi.ctype*
function Utils.getType(v)
	if type(v) == "table" and v.ClassName then
		return v.ClassName
	elseif type(v) == "table" and v.typename then
		return v.typename
	elseif type(v) == "userdata" and v.type then
		return v:type()
	elseif type(v) == "cdata" then
		return v.typename or ffi.typeof(v)
	else
		return type(v)
	end
end


---@param value any
---@param t table|string|ffi.ctype*
---@return boolean
function Utils.isType(value, t)
	if type(t) == "table" then
		local mt = getmetatable(value)
		while mt do
			if mt == t or mt.ClassName == t.ClassName then
				return true
			end
			mt = getmetatable(mt)
		end
		return false
	end

	local vtype = type(value)
	if t == "cstruct" and (vtype == "table" or vtype == "cdata") and value.typename then
		return true
	end

	return Utils.getType(value) == t
end


-- TODO: add cstruct copy support
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

	return setmetatable(result, getmetatable(t))
end

---@param t table
---@return table
function Utils.deepCopy(t)
	return copyTable(t, {})
end


---@param t table
---@return table
function Utils.shallowCopy(t)
	local result = {}
	for k, v in pairs(t) do
        result[k] = v
	end
	return result
end


---@param t1 table
---@param t2 table
---@param ignoreArrayOrder boolean
---@return boolean
function Utils.isTableEqual(t1, t2, ignoreArrayOrder)
	return t1 == t2 or (Utils.containsTable(t1, t2, ignoreArrayOrder) and Utils.containsTable(t2, t1, ignoreArrayOrder))
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


local vertexFormat3D = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoords", "float", 2},
	{"VertexNormal", "float", 3}
}


---@param size Vector3
---@param segments integer
---@param rings integer
---@return love.Mesh
function Utils.newSphereMesh(size, segments, rings)
	local verts = {}
	local indices = {}
	local radius = size / 2

	table.insert(verts, {0,radius.y,0,.5,0,0,1,0})

	for s=0, segments-1 do
		local angle1 = s * (2 * math.pi) / segments;

		for r=0, rings-1 do
			local angle2 = (r + 1) * math.pi / (rings + 1);

            local nx = math.sin(angle2) * math.cos(angle1);
            local ny = math.cos(angle2);
            local nz = math.sin(angle2) * math.sin(angle1);


			local id1 = 2 + r * rings + s
			local id2 = 2 + r * rings + ((s + 1) % segments)
			local id3 = 2 + (r + 1) * rings + s
			local id4 = 2 + (r + 1) * rings + ((s + 1) % segments)

			if r+1 == rings then
				id3 = 2 + rings * segments
				id4 = id3
			end

			verts[id1] = {nx*radius.x, ny*radius.y, nz*radius.z, 1 - r / segments, s / rings, nx, ny, nz}
			Lume.push(indices, id1, id2, id3, id2, id4, id3)

			if r == 0 then
				Lume.push(indices, id1, 1, id2)
			end
		end
	end

	table.insert(verts, {0,-radius.y,0,.5,1,0,-1,0})

	local mesh = love.graphics.newMesh(vertexFormat3D, verts, "triangles", "static")
	mesh:setVertexMap(indices)
	return mesh
end



function Utils.newConeMesh(size, segments)
	local verts = {}
	local indices = {}
	local radius = size / 2

	table.insert(verts, {0,0,0,.5,0,0,1,0})

	for s=0, segments-1 do
		local angle = s * (2 * math.pi) / segments;
		local nx = math.cos(angle);
		local ny = math.sin(angle);

		local id1 = 2 + s
		local id2 = 2 + ((s + 1) % segments)

		Lume.push(indices, id1, 1, id2)
		Lume.push(indices, id1, id2, 2 + segments)
		verts[id1] = {nx*radius.x, ny*radius.y, radius.z, s / segments, 0, nx, ny, 0.5}
	end

	table.insert(verts, {0,0,radius.z,.5,.5,-1,0,0})

	local mesh = love.graphics.newMesh(vertexFormat3D, verts, "triangles", "static")
	mesh:setVertexMap(indices)
	return mesh
end



---@param ... number[]
---@return love.Image
function Utils.newGradient(...)
	local n = select("#", ...)
	local data = love.image.newImageData(1, n)

	for i=1, n do
		local c = select(i, ...)
		data:setPixel(0, i-1, c[1], c[2], c[3], c[4])
	end

	local img = love.graphics.newImage(data)
	img:setFilter("linear", "linear")

	return img
end



---@param size Vector2
---@param color number[]
---@return love.Image
function Utils.newColorImage(size, color)
	local data = love.image.newImageData(size.width, size.height)

	data:mapPixel(function() return color[1], color[2], color[3], color[4] end)
	return love.graphics.newImage(data, {linear = true})
end


return Utils