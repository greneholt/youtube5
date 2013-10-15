isProviderEnabled = ->
  true

checkResponseForRequest = (event, requestInfo) ->
  getResponseForRequest requestInfo

loadPlayer = (playerId, requestInfo) ->
  loadVideo requestInfo, (meta) ->
    meta.volume = 1
    meta.preferredVideoWidth = 1280
    injectVideo playerId, meta

updateVolumeCallback = (volume) ->
  # do something eventually