# This file expects the following functions to be defined:
#   checkResponseForRequest(event, requestInfo) - returns a string response to the request
#   loadPlayer(playerId, requestInfo) - initiate the process of loading the video
#   updateVolumeCallback(level) - update the volume preference to the specified value

players = {}

getFlashvars = (el) ->
  flashvars = el.getAttribute("flashvars")
  flashvars = flashvars.getAttribute("value")  if flashvars = el.querySelector("param[name=flashvars]")  unless flashvars
  flashvars

injectVideo = (playerId, meta) ->
  meta.volumeCallback = updateVolumeCallback
  # these messages are sent to iframes as well, so check if the requested video actually belongs to this frame
  players[playerId].injectVideo meta if players[playerId]

document.addEventListener "beforeload", ((event) ->
  return if event.target.youtube5allowedToLoad
  requestInfo = {}
  if event.target instanceof HTMLObjectElement or event.target instanceof HTMLEmbedElement
    requestInfo.type = "plugin"
  else if event.target instanceof HTMLIFrameElement
    requestInfo.type = "iframe"
  else if event.target instanceof HTMLScriptElement
    requestInfo.type = "script"
  else
    event.target.youtube5allowedToLoad = true
    return

  #
  #	Some websites can have flash checking disabled by adding the following to the getRequestParameter function of swfobject.
  #
  #	if(c=='detectflash')return'false';
  #
  requestInfo.location = window.location.href
  requestInfo.url = event.url
  requestInfo.flashvars = getFlashvars(event.target)

  result = checkResponseForRequest event, requestInfo

  if result is "video"
    # sometimes both <embed> and <object> will trigger a beforeload event, even after one of the two has been removed
    return unless event.target.parentNode

    event.preventDefault()
    playerId = Math.round(Math.random() * 1000000000)

    # sometimes the scroll dimmensions of the video are zero, so fall back to the designated width and height
    width = event.target.scrollWidth
    height = event.target.scrollHeight
    if width is 0 or height is 0
      width = event.target.width
      height = event.target.height
    event.target.youtube5allowedToLoad = true
    flashvars = getFlashvars event.target
    replace = event.target

    # little hack to get around YouTube's flash detection. This moves the YouTube5 player one node up the dom tree, breaking their code and preventing it from being removed.
    replace = replace.parentNode  if replace.parentNode.id is "player-api" or replace.parentNode.id is "player-api-legacy"

    players[playerId] = newPlayer(replace, width, height)
    loadPlayer playerId, requestInfo

  else if result is "block"
    event.preventDefault()
  else if result is "allow"
    event.target.youtube5allowedToLoad = true
), true

# Make YouTube load a new page when navigating to a suggested video
document.addEventListener "DOMContentLoaded", ((event) ->
  if getDomain(window.location.href) is "youtube.com"
    script = document.createElement("script")
    script.text = "history.pushState = null;"
    document.body.appendChild script
), true
