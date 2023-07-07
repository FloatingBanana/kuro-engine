local Utils = {
	preprocessShader = require "src.engine.utils.preprocessShader"
}

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

function Utils.getCurrentFont()
	return fonts[currFont]
end

function Utils.newSquareMesh(size)
	local w, h = size.width, size.height
	return lg.newMesh({
        {0,0,0,0},
        {w,0,1,0},
        {0,h,0,1},
        {w,h,1,1}
    }, "strip", "static")
end

return Utils