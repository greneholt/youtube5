canLoad = (event, requestInfo) ->
  safari.self.tab.canLoad event, requestInfo

loadVideo = (playerId, requestInfo) ->
  safari.self.tab.dispatchMessage "loadVideo",
    playerId: playerId
    requestInfo: requestInfo

updateVolume = (volume) ->
  safari.self.tab.dispatchMessage "updateVolume", volume

safari.self.addEventListener "message", (event) ->
  if event.name == "injectVideo"
    injectVideo event.message.playerId, event.message.meta
, true