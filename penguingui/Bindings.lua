Binding = setmetatable(
  {},
  {
    __call = function(t, ...)
      return t.value(...)
    end
  }
)

Binding.proxyTable = {
  __index = function(t, k)
    local out = t._instance[k]
    if out ~= nil then
      return out
    else
      return Binding.proxyTable[k]
    end
  end,
  __newindex = function(t, k, v)
    local instance = t._instance
    local old = instance[k]
    local new = v
    instance[k] = new
    if old ~= v then
      local listeners = instance.listeners
      if listeners and listeners[k] then
        local keyListeners = listeners[k]
        for _,keyListener in ipairs(keyListeners) do
          new = keyListener(instance, k, old, new) or new
        end
      end
    end
  end,
  __pairs = function(t)
    return pairs(t._instance)
  end,
  __ipairs = function(t)
    return ipairs(t._instance)
  end,
  __add = function(a, b)
    return a._instance + (b._instance or b)
  end,
  __mul = function(a, b)
    return a._instance * (b._instance or b)
  end,
  __div = function(a, b)
    return a._instance / (b._instance or b)
  end,
  __mod = function(a, b)
    return a._instance % (b._instance or b)
  end,
  __pow = function(a, b)
    return a._instance ^ (b._instance or b)
  end,
  __unm = function(a)
    return -a._instance
  end,
  __concat = function(a, b)
    return a._instance .. (b._instance or b)
  end,
  __len = function(a)
    return #a._instance
  end,
  __eq = function(a, b)
    return a._instance == b._instance
  end,
  __lt = function(a, b)
    return a._instance < b._instance
  end,
  __le = function(a, b)
    return a._instance <= b._instance
  end,
  __call = function(t, ...)
    return t._instance(...)
  end
}

function Binding.isValue(object)
  return type(object) == "table"
    and getmetatable(object._instance) == Binding.valueTable
end

Binding.valueTable = {
  tostring = function(self)
    local out = Binding.proxy(setmetatable({}, Binding.valueTable))
    out.value = tostring(self.value)
    self:addListener(
      "value",
      function(t, k, old, new)
        out.value = tostring(new)
      end
    )
    return out
  end,
  add = function(a, b)
    local out = Binding.proxy(setmetatable({}, Binding.valueTable))
    if Binding.isValue(b) then
      out.value = a.value + b.value
      a:addListener(
        "value",
        function(t, k, old, new)
          out.value = new + b.value
        end
      )
      b:addListener(
        "value",
        function(t, k, old, new)
          out.value = a.value + new
        end
      )
    else
      out.value = a.value + b
      a:addListener(
        "value",
        function(t, k, old, new)
          out.value = new + b
        end
      )
    end
    return out
  end
}

Binding.valueTable.__index = Binding.valueTable

function Binding.value(t, k)
  if type(k) == "string" then -- Single key
    local value = Binding.proxy(setmetatable({}, Binding.valueTable))
    value.value = t[k]
    t:addListener(
      k,
      function(t, k, old, new)
        value.value = new
      end
    )
    return value
  else -- Table of keys TODO
    
  end
end

-- Adds a listener to the specified key that is called when the key's value
-- changes.
--
-- @param key The key to track changes to
-- @param listener The function to call upon the value of the key changing.
--      The function should have the arguments (t, k, old, new) where:
--           t is the table in which the change happened.
--           k is the key whose value changed.
--           old is the old value of the key.
--           new is the new value of the key.
function Binding.proxyTable:addListener(key, listener)
  local listeners = self.listeners
  if not listeners then
    listeners = {}
    self.listeners = listeners
  end
  local keyListeners = listeners[key]
  if not keyListeners then
    keyListeners = {}
    listeners[key] = keyListeners
  end
  table.insert(keyListeners, listener)
end

-- Binds the key in the specified table to the given value
--
-- @param table The table where the key to be bound is.
-- @param kkey The key to be bound.
-- @param value The value to bind to.
function Binding.bind(table, key, value)
  value:addListener(
    "value",
    function(t, k, old, new)
      table[key] = new
    end
  )
end

-- Binds the target value to the source value.
--
-- @param sourceKey The name of the key to be bound by.
-- @param targetComponent The target table to bind.
-- @param targetKey The target key to bind.
function Binding.proxyTable:bind(sourceKey, targetComponent, targetKey)
  local targetLen = #targetKey
  local transformations = {}
  self:addListener(
    sourceKey,
    function(t, k, old, new)
      local targetTable = targetComponent
      for i=1,targetLen - 1,1 do
        targetTable = targetTable[targetKey[i]]
      end
      for _,transformation in ipairs(transformations) do
        new = transformation(t, k, old, new)
      end
      targetTable[targetKey[targetLen]] = new
    end
  )
  return transformations
end

function Binding.proxy(instance)
  return setmetatable(
    {_instance = instance},
    Binding.proxyTable
  )
end
