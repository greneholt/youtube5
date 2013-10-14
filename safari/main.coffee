getPreference = (name) ->
  safari.extension.settings[name]

setPreference = (name, value) ->
  safari.extension.settings[name] = value

injectVideo = (event, playerId, meta) ->
  meta.volume = getPreference('volume')
  event.target.page.dispatchMessage "injectVideo",
    playerId: playerId
    meta: meta

safari.application.addEventListener "message", ((event) ->
  if event.name is "canLoad"
    event.message = canLoad event.message
  else if event.name is "loadVideo"
    videoInfo = event.message
    playerId = videoInfo.playerId
    url = videoInfo.url
    flashvars = videoInfo.flashvars

    callback = (meta) ->
      injectVideo event, playerId, meta

    loadVideo url, flashvars, callback
  else if event.name is "updateVolume"
    updateVolume event.message
), true