getPreference = (name) ->
  safari.extension.settings[name]

setPreference = (name, value) ->
  safari.extension.settings[name] = value

safari.application.addEventListener "message", ((event) ->
  if event.name is "canLoad"
    event.message = getResponseForRequest event.message
  else if event.name is "loadPlayer"
    playerId = event.message.playerId
    requestInfo = event.message.requestInfo

    callback = (meta) ->
      meta.volume = getPreference('volume')
      event.target.page.dispatchMessage "injectVideo",
        playerId: playerId
        meta: meta

    loadVideo requestInfo, callback
  else if event.name is "updateVolume"
    updateVolume event.message
), true