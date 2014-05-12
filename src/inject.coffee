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
    playerId = event.target.id || Math.round(Math.random() * 1000000000)
    return if players[playerId] # prevent creating a player for the same element twice

    # sometimes the scroll dimmensions of the video are zero, so fall back to the designated width and height
    width = event.target.scrollWidth
    height = event.target.scrollHeight
    if width is 0 or height is 0
      width = event.target.width
      height = event.target.height
    flashvars = getFlashvars event.target
    replace = event.target

    # Little(ish) hack to get around YouTube's flash detection. This places
    # the player in the page outside the normal flow but in the same place as
    # the original video. This prevents their code from removing it.
    if getDomain(window.location.href) is "youtube.com"
      position = findPosition replace
      container = create 'div', document.body
      container.style.position = 'absolute'
      container.style.left = "#{position[0]}px"
      container.style.top = "#{position[1]}px"
      target = create 'div', container
      replace.parentNode.removeChild replace
      replace = target

    players[playerId] = new Player replace, width, height
    loadPlayer playerId, requestInfo

  else if result is "block"
    event.preventDefault()
  else if result is "allow"
    event.target.youtube5allowedToLoad = true
), true

# Make YouTube truly reload pages rather than using history.pushState
document.addEventListener "DOMContentLoaded", ((event) ->
  if getDomain(window.location.href) is "youtube.com"
    historyLength = history.length
    id = setInterval ->
      if history.length != historyLength
        clearInterval id
        window.location.reload()
    , 100
), true
