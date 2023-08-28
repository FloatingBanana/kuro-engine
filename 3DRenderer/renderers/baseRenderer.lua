--- @alias MeshPartConfig {castShadows: boolean, ignoreLighting: boolean, worldMatrix: Matrix, onDraw: function}

--- @class BaseRenderer: Object
---
--- @field private screensize Vector2
--- @field protected ppeffects BasePostProcessingEffect[]
--- @field resultCanvas love.Canvas
--- @field depthCanvas love.Canvas
--- @field protected meshparts table<MeshPart, MeshPartConfig>
--- @field protected lights BaseLight[]
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): BaseRenderer
local Renderer = Object:extend()

function Renderer:new(screensize, postProcessingEffects)
    self.screensize = screensize
    self.ppeffects = postProcessingEffects

    self.resultCanvas = lg.newCanvas(screensize.width, screensize.height, {format = "rgba16f"})
    self.depthCanvas = lg.newCanvas(screensize.width, screensize.heiht, {format = "depth32f", readable = true})

    self.meshparts = {}
    self.lights = {}
end


---@param parts MeshPart[]
---@param settings MeshPartConfig
function Renderer:addMeshPart(parts, settings)
    for i, part in ipairs(parts) do
        self.meshparts[part] = Lume.clone(settings)
    end
end


---@param ... BaseLight
function Renderer:addLights(...)
    Lume.push(self.lights, ...)
end


---@param light BaseLight
function Renderer:removeLight(light)
    for i, l in ipairs(self.lights) do
        if l == light then
            table.remove(self.lights, i)
            return
        end
    end
end


---@param part MeshPart
---@return MeshPartConfig
function Renderer:getMeshpartSettings(part)
    return self.meshparts[part]
end


function Renderer:renderMeshes()
    error("Not implemented")
end


---@param position Vector3
---@param view Matrix
---@param projection Matrix
function Renderer:render(position, view, projection)
    lg.push("all")
    self:renderMeshes(position, view, projection)
    lg.pop()

    lg.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:onPostRender(self, result, view, projection)
    end

    lg.pop()
    lg.draw(result)
end


return Renderer