local BaseLight = Object:extend()

local depthShader = lg.newShader [[
varying vec3 v_normal;

#ifdef VERTEX
attribute vec3 VertexNormal;

uniform mat4 u_viewProj;
uniform mat4 u_world;
uniform mat3 u_invTranspWorld;

vec4 position(mat4 transformProjection, vec4 position) {
    v_normal = VertexNormal * u_invTranspWorld;
    vec4 result = u_viewProj * u_world * position;

    //result.y *= -1.0;
    return result;
}
#endif

#ifdef PIXEL
uniform vec3 lightDir;

void effect() {
    float bias = max(0.05 * (1.0 - dot(lightDir, v_normal)), 0.005);
    gl_FragDepth = gl_FragCoord.z + (gl_FrontFacing ? bias : 0.0);
}
#endif
]]

function BaseLight:new(position, ambient, diffuse, specular, shadowMapSize)
    self.position = position

    self.ambient = ambient
    self.diffuse = diffuse
    self.specular = specular

    self.near = 1
    self.far = 7

    self.enabled = true

    self.shadowmap = lg.newCanvas(shadowMapSize.width, shadowMapSize.height, {format = "depth16", readable = true})
    self.shadowmap:setFilter("nearest", "nearest")
    self.shadowmap:setWrap("clamp")

    self.depthShader = depthShader
end

local currCanvas = nil
local currCullMode = nil
local currBlendMode = nil
local currAlphaBlendMode = nil
local currShader = nil
function BaseLight:beginLighting()
    currCanvas = lg.getCanvas()
    currCullMode = lg.getMeshCullMode()
    currBlendMode, currAlphaBlendMode = lg.getBlendMode()
    currShader = lg.getShader()

    lg.setCanvas {depthstencil = self.shadowmap}
    lg.clear()
    lg.setDepthMode("lequal", true)
    lg.setMeshCullMode("none")
    lg.setBlendMode("replace")
    lg.setShader(depthShader)
end

function BaseLight:endLighting()
    lg.setCanvas(currCanvas)
    lg.setMeshCullMode(currCullMode)
    lg.setBlendMode(currBlendMode, currAlphaBlendMode)
    lg.setShader(currShader)
end

return BaseLight