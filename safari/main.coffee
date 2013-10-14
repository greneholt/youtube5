getPreference = (name) ->
  safari.extension.settings[name]

setPreference = (name, value) ->
  safari.extension.settings[name] = value

safari.application.addEventListener "message", ((event) ->
  if event.name is "canLoad"
    event.message = canLoad event.message
  else if event.name is "loadVideo"
    loadVideo event
  else if event.name is "updateVolume"
    updateVolume event.message
), true