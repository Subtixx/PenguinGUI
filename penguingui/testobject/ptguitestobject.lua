function init(virtual)
  if not virtual then
    storage.consoleStorage = storage.consoleStorage or {}
    object.setInteractive(true)
  end
end

function onConsoleStorageRecieve(consoleStorage)
  storage.consoleStorage = consoleStorage
end

function onInteraction(args)
  local interactionConfig = config.getParameter("interactionConfig")
  
  local development = true
  if development then
    local consoleScripts = PtUtil.library()
    for _,script in ipairs(interactionConfig.scripts) do
      table.insert(consoleScripts, script)
    end
    interactionConfig.scripts = consoleScripts
  else
    table.insert(interactionConfig.scripts, 1, "/penguingui.lua")
  end

  interactionConfig.scriptStorage = storage.consoleStorage
  
  return {"ScriptConsole", interactionConfig}
end
