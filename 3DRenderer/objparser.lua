-- Default values
local defaultuv = {u=0, v=0}
local defaultnormal = {x=0, y=0, z=0}

-----------------------------
---------- Helpers ----------
-----------------------------
local function crossNormalized(v1x, v1y, v1z, v2x, v2y, v2z)
    local crossx = v1y * v2z - v2y * v1z
    local crossy = v1x * v2z - v2x * v1z
    local crossz = v1x * v2y - v2x * v1y

    local invMag = 1 / math.sqrt(crossx*crossx + crossy*crossy + crossz*crossz)

    return crossx * invMag,
           crossy * invMag,
           crossz * invMag
end

local function tonumberMult(t)
    for k, v in pairs(t) do
        t[k] = tonumber(v)
    end
    return t
end

local function parseLine(line)
    local f = line:gmatch("[^%s]+")
    local param = f()
    local args = {}

    for arg in f do
        table.insert(args, arg)
    end

    return param, args
end


-----------------------------
---------- Parsers ----------
-----------------------------
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
            texture.offset = tonumberMult({u = args[i+1], v = args[i+2] or 0})

        elseif args[i] == "-s" then
            texture.scale = tonumberMult({u = args[i+1], v = args[i+2] or 0})

        elseif args[i] == "-t" then
            texture.turbulence = tonumberMult({u = args[i+1], v = args[i+2] or 0})

        elseif args[i] == "-texres" then
            texture.resolution = args[i+1]

        elseif args[i] == "-clamp" then
            texture.clamp = args[i+1] == "on"

        elseif args[i] == "-bm" then
            texture.bumpMultiplier = tonumber(args[i+1])

        elseif args[i] == "-imfchan" then
            texture.bumpChannel = args[i+1]

        elseif args[i] == "-type" then
            texture.reflectionMapType = args[i+1]

        else
            texture.texture = args[i]
        end
    end

    return texture
end

local function ParseMtl(filename)
    local materials = {}
    local current = nil

    for line in love.filesystem.lines(filename) do
        local param, args = parseLine(line)

        if param == "newmtl" then
            current = {}
            materials[args[1]] = current

        elseif param == "Ka" then
            current.ambientColor = tonumberMult({args[1], args[2], args[3]})

        elseif param == "Kd" then
            current.diffuseColor = tonumberMult({args[1], args[2], args[3]})

        elseif param == "Ks" then
            current.specularColor = tonumberMult({args[1], args[2], args[3]})

        elseif param == "d" then
            current.transparence = 1 - tonumber(args[1])

        elseif param == "Tr" then
            current.transparence = tonumber(args[1])

        elseif param == "Tf" then
            current.transmissionFilter = tonumberMult({args[1], args[2], args[3]}) -- XYZ not supported

        elseif param == "Ni" then
            current.opticalDensity = tonumber(args[1])

        elseif param == "illum" then
            current.illuminationModel = tonumber(args[1])

        elseif param == "map_Ka" then
            current.ambientTexture = ParseTextureMap(args)

        elseif param == "map_Kd" then
            current.diffuseTexture = ParseTextureMap(args)

        elseif param == "map_Ks" then
            current.specularTexture = ParseTextureMap(args)
        end
    end

    return materials
end

local function Parseobj(filename, flipU, flipV, recalculateNormals)
    local materials = {}
    local objects = {}

    local thisobj = nil
    local thisobjpart = nil

    local positions = {}
    local normals = {}
    local texcoords = {}

    for line in love.filesystem.lines(filename) do
        local param, args = parseLine(line)

        -- Load material file
        if param == "mtllib" then
            local path = filename:match("(.+/)") or ""
            materials = ParseMtl(path..args[1])
        end

        -- Object definition
        if param == "o" then
            thisobj = {}
            objects[args[1]] = thisobj
        end

        -- Vertex
        if param == "v" then
            table.insert(positions, tonumberMult({
                x = args[1],
                y = args[2],
                z = args[3]
            }))
        end

        -- Texture coordinates
        if param == "vt" then
            local u = tonumber(args[1])
            local v = tonumber(args[2])

            table.insert(texcoords, {
                u = flipU and 1 - u or u,
                v = flipV and 1 - v or v
            })
        end

        -- Normals
        if param == "vn" then
            table.insert(normals, tonumberMult({
                x = args[1],
                y = args[2],
                z = args[3]
            }))
        end

        -- Set material
        if param == "usemtl" then
            thisobjpart = {
                material = materials[args[1]],
                vertices = {}
            }

            table.insert(thisobj, thisobjpart)
        end

        -- Faces
        if param == "f" then
            assert(#args == 3, "Model needs to be triangulated")

            for i, vert in ipairs(args) do
                local v, vt, vn = vert:match("(%d*)/(%d*)/(%d*)")

                local pos = positions[tonumber(v)]
                local tex = vt and texcoords[tonumber(vt)] or defaultuv
                local norm = vn and normals[tonumber(vn)] or defaultnormal

                table.insert(thisobjpart.vertices, {
                    pos.x, pos.y, pos.z,
                    tex.u, tex.v,
                    norm.x, norm.y, norm.z
                })
            end

            if recalculateNormals then
                local verts = thisobjpart.vertices

                local v1 = verts[#verts-2]
                local v2 = verts[#verts-1]
                local v3 = verts[#verts]

                local vfx, vfy, vfz = v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]
                local vlx, vly, vlz = v3[1] - v2[1], v3[2] - v2[2], v3[3] - v2[3]
                local normalx, normaly, normalz = crossNormalized(vfx,vfy,vfz, vlx,vly,vlz)

                -- normalx, normaly, normalz = -normalx, -normaly, -normalz

                v1[6], v1[7], v1[8] = normalx, normaly, normalz
                v2[6], v2[7], v2[8] = normalx, normaly, normalz
                v3[6], v3[7], v3[8] = normalx, normaly, normalz
            end
        end
    end

    local model = {
        materials = materials,
        objects = objects
    }

    return model
end

return Parseobj