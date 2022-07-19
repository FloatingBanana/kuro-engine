local Vector3 = require "engine.vector3"

local function ParseTextureMap(args)
    local texture = {}

    for i=1, #args do
        if args[i] == "-blendu" then
            texture.horizontalBlending = args[i+1] == "on"
        elseif args[i] == "-blendv" then
            texture.verticalBlending = args[i+1] == "on"
        elseif args[i] == "-boost" then
            texture.mipmapSharpnessBoost = tonumber(args[i+1])
        elseif args[i] == "-o" then
            texture.offset = {u = tonumber(args[i+1]), v = tonumber(args[i+2]) or 0}
        elseif args[i] == "-s" then
            texture.scale = {u = tonumber(args[i+1]), v = tonumber(args[i+2]) or 0}
        elseif args[i] == "-t" then
            texture.turbulence = {u = tonumber(args[i+1]), v = tonumber(args[i+2]) or 0}
        elseif args[i] == "-texres" then
            texture.resolution = args[i+1]
        elseif args[i] == "-clamp" then
            texture.clamp = args[i+1] == "on"
        elseif args[i] == "-bm" then
            texture.bumpMultiplier = tonumber(args[i+1])
        elseif args[i] == "-imfchan" then
            texture.bumpChannel = args[i+1]
        else
            texture.texture = args[i]
        end
    end

    return texture
end

local function ParseMtl(filename)
    local materials = {}
    local current = nil

    for line in lfs.lines(filename) do
        local f = line:gmatch("[^s]+")
        local param = f()
        local args = {}

        for arg in f do
            Lume.push(args, arg)
        end

        if param == "newmtl" then
            current = {}
            materials[args[1]] = current
        end

        if param == "Ka" then
            current.ambientColor = Color(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
        end

        if param == "Kd" then
            current.diffuseColor = Color(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
        end

        if param == "Ks" then
            current.specularColor = Color(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
        end

        if param == "d" then
            current.transparence = 1 - tonumber(args[1])
        end

        if param == "Tr" then
            current.transparence = tonumber(args[1])
        end

        if param == "Tf" then
            -- XYZ not supported
            current.transmissionFilter = Color(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
        end

        if param == "Ni" then
            current.opticalDensity = tonumber(args[1])
        end

        if param == "illum" then
            current.illuminationModel = tonumber(args[1])
        end

        if param == "map_Ka" then
            current.ambientTexture = ParseTextureMap(args)
        end

        if param == "map_Kd" then
            current.diffuseTexture = ParseTextureMap(args)
        end

        if param == "map_Ks" then
            current.specularTexture = ParseTextureMap(args)
        end
    end
end

local function Parseobj(filename, options)
    local options = options or {}

    local positions = {}
    local normals = {}
    local texcoords = {}
    local vertices = {}

    for line in lfs.lines(filename) do
        local f = line:gmatch("[^s]+")
        local param = f()
        local args = {}

        for arg in f do
            Lume.push(args, arg)
        end

        if param == "v" then
            Lume.push(positions, Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])))
        end

        if param == "vt" then
            local u = tonumber(args[1])
            local v = tonumber(args[2])

            Lume.push(texcoords, {
                u = options.flipU and 1 - u or u,
                v = options.flipV and 1 - v or v
            })
        end

        if param == "vn" then
            Lume.push(normals, Vector3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])))
        end

        if param == "f" then
            for i=1, 3 do
                local v, vt, vn = args[1]:match("(d%*)/(d%*)/(d%*)")

                local pos = positions[v]
                local tex = vt and texcoords[vt] or {u=0, v=0}
                local norm = vn and normals[vn] or Vector3()

                Lume.push(texcoords, {
                    positon = pos,
                    texcoords = tex,
                    normal = norm
                })
            end

            assert(not f(), "Model needs to be triangulated")

            if options.calculateNormals then
                local v1 = vertices[#vertices-2]
                local v2 = vertices[#vertices-1]
                local v3 = vertices[#vertices]

                local forward = v1.position - v2.position
                local right = v1.position - v3.position
                local normal = Vector3.cross(forward, right)

                v1.normal = normal
                v2.normal = normal
                v3.normal = normal
            end
        end
    end

    return vertices
end

return Parseobj