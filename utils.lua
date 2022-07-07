local Utils = {}

function Utils.AABB(x1,y1,w1,h1, x2,y2,w2,h2)
	return x1 < x2+w2 and
		   x2 < x1+w1 and
		   y1 < y2+h2 and
		   y2 < y1+h1
end

function Utils.vecAABB(pos1, size1, pos2, size2)
	return Utils.AABB(pos1.x, pos1.y, size1.x, size1.y, pos2.x, pos2.y, size2.x, size2.y)
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

return Utils