checkResponseForRequest = (event, requestInfo) ->
  safari.self.tab.canLoad event, requestInfo

loadPlayer = (playerId, requestInfo) ->
  safari.self.tab.dispatchMessage "loadPlayer",
    playerId: playerId
    requestInfo: requestInfo

updateVolumeCallback = (volume) ->
  safari.self.tab.dispatchMessage "updateVolume", volume

safari.self.addEventListener "message", (event) ->
  if event.name == "injectVideo"
    injectVideo event.message.playerId, event.message.meta
, true