isProviderEnabled = (name) ->
  safari.extension.settings["#{name}Enabled"]

safari.application.addEventListener "message", ((event) ->
  if event.name is "canLoad"
    event.message = getResponseForRequest event.message
  else if event.name is "loadPlayer"
    playerId = event.message.playerId
    requestInfo = event.message.requestInfo

    callback = (meta) ->
      meta.volume = safari.extension.settings.volume
      meta.preferredVideoWidth = safari.extension.settings.preferredVideoWidth
      meta.autoplay = false if safari.extension.settings.preventAutoplay
      event.target.page.dispatchMessage "injectVideo",
        playerId: playerId
        meta: meta

    loadVideo requestInfo, callback
  else if event.name is "updateVolume"
    safari.extension.settings.volume = event.message
), true