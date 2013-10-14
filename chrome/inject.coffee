getPreference = (name) ->
  100

setPreference = (name, value) ->
  null

checkResponseForRequest = (event, requestInfo) ->
  getResponseForRequest requestInfo

loadPlayer = (playerId, requestInfo) ->
  loadVideo requestInfo, (meta) ->
    meta.volume = 100
    injectVideo playerId, meta

updateVolumeCallback = (volume) ->
  updateVolume volume