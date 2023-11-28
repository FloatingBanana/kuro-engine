--- @alias MeshPartConfig {castShadows: boolean, ignoreLighting: boolean, worldMatrix: Matrix, animator: ModelAnimator, onDraw: function}

--- @class BaseRenderer: Object
---
--- @field private screensize Vector2
--- @field protected ppeffects BasePostProcessingEffect[]
--- @field resultCanvas love.Canvas
--- @field depthCanvas love.Canvas
--- @field velocityBuffer love.Canvas
--- @field protected meshparts table<MeshPart, MeshPartConfig>
--- @field protected lights BaseLight[]
--- @field protected previousTransformations table<MeshPart, Matrix>
---
--- @overload fun(screenSize: Vector2, postProcessingEffects: BasePostProcessingEffect[]): BaseRenderer
local Renderer = Object:extend()

function Renderer:new(screensize, postProcessingEffects)
    self.screensize = screensize
    self.ppeffects = postProcessingEffects

    self.resultCanvas = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rgba16f"})
    self.depthCanvas = love.graphics.newCanvas(screensize.width, screensize.heiht, {format = "depth32f", readable = true})
    self.velocityBuffer = love.graphics.newCanvas(screensize.width, screensize.height, {format = "rg8"})

    self.meshparts = {}
    self.lights = {}
    self.previousTransformations = {} -- for velocity buffer
end


---@param parts MeshPart[]
---@param settings MeshPartConfig
function Renderer:addMeshPart(parts, settings)
    for i, part in ipairs(parts) do
        self.meshparts[part] = Lume.clone(settings)
        self.previousTransformations[part] = settings.worldMatrix:clone()
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


---@param camera Camera
function Renderer:render(camera)
    love.graphics.push("all")
    self:renderMeshes(camera)
    love.graphics.pop()

    love.graphics.push("all")

    local result = self.resultCanvas
    for i, effect in ipairs(self.ppeffects) do
        result = effect:onPostRender(self, result, camera)
    end

    love.graphics.pop()
    love.graphics.draw(result)

    -- Store mesh transfomation from this frame to calculate the velocity buffer on the next frame
    for meshpart, prevMatrix in pairs(self.previousTransformations) do
        local settings = self:getMeshpartSettings(meshpart)

        self.previousTransformations[meshpart] = settings.worldMatrix * camera.viewProjectionMatrix
    end
end


return Renderer