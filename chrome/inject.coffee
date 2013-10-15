getPreference = (name) ->
  '720p'

setPreference = (name, value) ->
  null

checkResponseForRequest = (event, requestInfo) ->
  getResponseForRequest requestInfo

loadPlayer = (playerId, requestInfo) ->
  loadVideo requestInfo, (meta) ->
    meta.volume = 1
    injectVideo playerId, meta

updateVolumeCallback = (volume) ->
  updateVolume volume