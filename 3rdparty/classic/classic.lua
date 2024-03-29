--
-- classic
--
-- Copyright (c) 2014, rxi
--
-- This module is free software; you can redistribute it and/or modify it under
-- the terms of the MIT license. See LICENSE for details.
--

-- Modified to include annotations and to store a list of classes inside engine/kuro.lua

local Kuro = require "engine.kuro"

--- Base class for all other classes. Uses the classic.lua library.
--- @class Object
--- @field public ClassName string
local Object = {ClassName = "Object"}
Object.__index = Object

Kuro.classes["Object"] = Object


function Object:new()
end


--- Creates a child class of this object.
---@param className string
--- @return any
function Object:extend(className)
  local cls = {}
  for k, v in pairs(self) do
    if k:find("__") == 1 then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.super = self
  setmetatable(cls, self)

  cls.ClassName = className
  Kuro.classes[className] = cls
  return cls
end


--- Implements another class into this one
---@param ... Object
function Object:implement(...)
  for _, cls in pairs({...}) do
    for k, v in pairs(cls) do
      if self[k] == nil and type(v) == "function" then
        self[k] = v
      end
    end
  end
end


--- Checks if this object belongs to this class.
--- @param T Object Class.
--- @return boolean
function Object:is(T)
  local mt = getmetatable(self)
  while mt do
    if mt == T then
      return true
    end
    mt = getmetatable(mt)
  end
  return false
end


---@private
function Object:__tostring()
  return "Object"
end


---@private
function Object:__call(...)
  local obj = setmetatable({}, self)
  obj:new(...)
  return obj
end


return Object
