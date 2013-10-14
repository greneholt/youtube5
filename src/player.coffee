create = (name, parent, className) ->
  elem = document.createElement(name)
  elem.className = className  if className
  parent.appendChild elem
  elem

formatTime = (seconds) ->
  m = Math.floor(seconds / 60)
  s = Math.floor(seconds % 60)
  m = "0" + m  if m < 10
  s = "0" + s  if s < 10
  m + ":" + s

findPosition = (el) ->
  left = top = 0
  loop
    left += el.offsetLeft
    top += el.offsetTop
    break unless el = el.offsetParent
  [left, top]

addClass = (el, className) ->
  el.className += " " + className

removeClass = (el, className) ->
  el.className = el.className.replace(new RegExp("\\b" + className + "\\b"), "")

hasClass = (el, className) ->
  el.className.indexOf(className) isnt -1

focusedPlayer = undefined
newPlayer = (replace, width, height) ->
  self = {}
  self.width = width
  self.height = height
  self.floating = false
  self.hovered = false
  self.originalPlayer = replace
  self.hoverTimeoutId = null
  self.revert = ->
    self.placeholder.parentNode.replaceChild self.originalPlayer, self.placeholder

  self.placeholder = document.createElement("div")
  self.placeholder.className = "youtube5placeholder"
  self.placeholder.style.width = self.width + "px"
  self.placeholder.style.height = self.height + "px"
  self.placeholder.setAttribute "data-clean", "yes" # prevent Feedly from stripping style attributes
  self.container = create("div", self.placeholder, "youtube5container")
  self.container.style.width = self.width + "px"
  self.container.style.height = self.height + "px"
  self.container.style.position = "relative"
  self.container.style.margin = "0 auto"
  self.player = create("div", self.container, "youtube5player youtube5loading")
  self.player.style.width = "100%"
  self.player.style.height = "100%"
  self.topOverlay = create("div", self.player, "youtube5top-overlay")
  self.bottomOverlay = create("div", self.player, "youtube5bottom-overlay")
  self.info = create("div", self.player, "youtube5info")
  self.useOriginal = create("div", self.info, "youtube5use-original youtube5show-on-waiting")
  self.useOriginal.innerHTML = "&crarr; Use original player"
  self.useOriginal.addEventListener "click", self.revert, false
  replace.parentNode.replaceChild self.placeholder, replace
  self.updateHoverTimeout = ->
    unless self.hovered
      self.hovered = true
      addClass self.player, "youtube5hover"
    else window.clearTimeout self.hoverTimeoutId  if self.hoverTimeoutId isnt null
    self.hoverTimeoutId = window.setTimeout(self.unHover, 2000)

  self.player.addEventListener "mousemove", self.updateHoverTimeout, false
  self.unHover = ->
    self.hovered = false

    # we need to temporarily disable the mousemove event listener because
    # for some reason safari fires a mousemove event when the cursor is changed.
    # https://bugs.webkit.org/show_bug.cgi?id=85343
    self.player.removeEventListener "mousemove", self.updateHoverTimeout, false
    window.setTimeout self.unHoverTransitionComplete, 500
    removeClass self.player, "youtube5hover"
    self.hoverTimeoutId = null

  self.unHoverTransitionComplete = ->
    self.player.addEventListener "mousemove", self.updateHoverTimeout, false

  self.updatePlayerSize = ->
    width = undefined
    height = undefined
    if self.floating
      width = self.video.videoWidth
      height = self.video.videoHeight
      minWidth = window.innerWidth * 0.8
      minHeight = window.innerHeight * 0.8
      if width > window.innerWidth
        width = window.innerWidth
      else width = minWidth  if width < minWidth
      if height > window.innerHeight
        height = window.innerHeight
      else height = minHeight  if height < minHeight
    else
      width = self.width
      height = self.height
    realAspectRatio = width / height
    nativeAspectRatio = self.video.videoWidth / self.video.videoHeight

    # the player is wider than necessary, so fit by height
    if realAspectRatio > nativeAspectRatio
      width = Math.round(height * nativeAspectRatio)
      height = height
    else # taller than necessary
      width = width
      height = Math.round(width / nativeAspectRatio)
    self.container.style.width = width + "px"
    self.container.style.height = height + "px"
    [
      width
      height
    ]

  self.updateTime = ->
    remaining = self.video.duration - self.video.currentTime
    self.timeElapsed.textContent = formatTime(self.video.currentTime)
    self.timeRemaining.textContent = "-" + formatTime(remaining)

  self.updatePlayed = ->
    self.played.style.width = self.position.value / 10 + "%"

  self.updateLoaded = ->
    return  if isNaN(self.video.duration) or self.video.buffered.length is 0
    self.loaded.style.width = self.video.buffered.end(0) / self.video.duration * 100 + "%"

  self.updatePosition = ->
    return  if isNaN(self.video.duration)
    self.position.value = self.video.currentTime / self.video.duration * 1000
    self.updatePlayed()
    self.updateTime()

  self.updateVolumeSlider = ->
    self.volumeSlider.value = self.video.volume * 100
    self.updateVolumeIndicator()

  self.updateVolumeIndicator = ->
    if self.video.volume > 0.75
      self.volume.className = "youtube5volume youtube5high"
    else if self.video.volume > 0.3
      self.volume.className = "youtube5volume youtube5med"
    else if self.video.volume > 0.02
      self.volume.className = "youtube5volume youtube5low"
    else
      self.volume.className = "youtube5volume youtube5off"

  self.seek = ->
    return  if isNaN(self.video.duration)
    self.video.currentTime = self.position.value / 1000 * self.video.duration
    self.updatePlayed()
    self.hideOverlay()

  self.showOverlay = ->
    addClass self.player, "youtube5overlayed"

  self.hideOverlay = ->
    removeClass self.player, "youtube5overlayed"

  self.playOrPause = ->
    if self.video.paused
      if hasClass(self.player, "youtube5waiting")
        removeClass self.player, "youtube5waiting"
        addClass self.player, "youtube5loading"
      self.video.play()
      self.removePlayLarge()
      self.hideOverlay()
    else
      self.video.pause()

    # set the focused player to this one
    focusedPlayer = self

  self.popInOrOut = ->
    return  if document.webkitIsFullScreen
    transitionCss = "width 0.5s ease-out, height 0.5s ease-out, left 0.5s ease-out, top 0.5s ease-out"
    if self.floating
      self.floating = false
      position = findPosition(self.container)

      # setup the starting point of the animation
      self.container.style.left = position[0] + "px"
      self.container.style.top = position[1] + "px"
      self.container.style.margin = "0 auto"
      self.container.offsetWidth # Force reflow hack. Makes the animation use the proper start positions.

      # enable the transition animation before making changes
      self.container.style.webkitTransition = transitionCss
      self.updatePlayerSize()
      self.container.style.left = self.originalPosition[0] + "px"
      self.container.style.top = self.originalPosition[1] + "px"
      self.container.addEventListener "webkitTransitionEnd", self.dockedTransitionComplete, false
    else
      self.floating = true
      self.originalPosition = findPosition(self.container)

      # when we change its dom position, the video stops playing
      paused = self.video.paused
      document.body.appendChild self.container
      self.video.play()  unless paused

      # setup the starting point of the animation
      self.container.style.position = "absolute"
      self.container.style.left = self.originalPosition[0] + "px"
      self.container.style.top = self.originalPosition[1] + "px"
      self.container.style.zIndex = 100000
      self.container.style.webkitBoxShadow = "0 0 20px #000"
      ignore = self.container.offsetWidth # Force reflow hack. Makes the animation use the proper start positions.

      # enable the transition animation before making changes
      self.container.style.webkitTransition = transitionCss
      size = self.updatePlayerSize()
      newWidth = size[0]
      newHeight = size[1]
      self.container.style.left = document.body.scrollLeft + (window.innerWidth - newWidth) / 2 + "px"
      self.container.style.top = document.body.scrollTop + (window.innerHeight - newHeight) / 2 + "px"
      self.container.addEventListener "webkitTransitionEnd", self.floatingTransitionComplete, false

  self.toggleFullScreen = ->
    if document.webkitIsFullScreen
      document.webkitCancelFullScreen()
    else
      self.player.webkitRequestFullScreen()

  self.floatingTransitionComplete = (event) ->
    return  unless event.propertyName is "left" # don't allow the animation to be short circuited by other transitions completing
    self.container.style.webkitTransition = null
    self.container.style.left = "50%"
    self.container.style.margin = "0 0 0 " + -self.container.clientWidth / 2 + "px"
    self.container.removeEventListener "webkitTransitionEnd", self.floatingTransitionComplete, false

  self.dockedTransitionComplete = (event) ->
    return  unless event.propertyName is "left" # don't allow the animation to be short circuited by other transitions completing
    self.container.style.webkitTransition = null
    paused = self.video.paused
    self.placeholder.appendChild self.container
    self.video.play()  unless paused

    # reset all the styles we changed
    self.container.style.position = "relative"
    self.container.style.left = null
    self.container.style.top = null
    self.container.style.zIndex = null
    self.container.style.webkitBoxShadow = null
    self.container.removeEventListener "webkitTransitionEnd", self.dockedTransitionComplete, false

  self.removePlayLarge = ->
    if self.playLarge
      self.player.style.background = null
      self.player.style.backgroundSize = null
      self.player.removeChild self.playLarge
      self.playLarge = null

  self.setVolume = (volume) ->
    self.video.muted = volume < 0.02
    self.video.volume = volume
    self.updateVolumeIndicator()
    self.meta.volumeCallback volume  if self.meta.volumeCallback

  self.changeQuality = (event) ->
    event.preventDefault()
    format = event.target.textContent
    paused = self.video.paused
    self.video.src = self.meta.formats[format]

    # only load the video if its already been playing
    self.video.preload = "auto"  if self.controls
    self.video.play()  unless paused
    nodes = event.target.parentNode.parentNode.childNodes
    i = 0
    while i < nodes.length
      nodes[i].className = ""
      i++
    event.target.parentNode.className = "youtube5current-format"

  self.initVideo = ->
    self.video.currentTime = self.meta.startTime  if self.meta.startTime
    self.updatePlayerSize()
    self.video.removeEventListener "loadedmetadata", self.initVideo, false

  self.videoReady = ->
    self.createControls()
    self.updatePosition()
    self.setVolume self.meta.volume
    self.video.removeEventListener "canplay", self.videoReady, false
    self.video.addEventListener "loadedmetadata", (->
      self.seek()
      self.updateTime()
    ), false

  self.loadStartTime = ->
    hashData = parseUrlEncoded(document.location.hash.replace(/^#/, ""))
    searchData = parseUrlEncoded(document.location.search.replace(/^\?/, ""))
    for attr of hashData
      searchData[attr] = hashData[attr]
    startTime = getStartTime(searchData)
    self.meta.startTime = startTime  if startTime

  self.injectVideo = (meta) ->

    # don't allow injecting the video twice
    return  if self.meta
    self.meta = meta
    if self.meta.error
      self.player.className = "youtube5player error"
      self.error = create("div", self.player, "youtube5error")
      self.error.innerHTML = self.meta.error
      return
    self.loadStartTime()
    self.video = document.createElement("video")
    self.video = create("video", self.player)
    self.video.src = meta.formats[meta.useFormat]
    self.player.insertBefore self.video, self.topOverlay
    if self.meta.autoplay
      focusedPlayer = this
      self.playOrPause()
    else
      removeClass self.player, "youtube5loading"
      addClass self.player, "youtube5waiting"
      self.player.style.background = "#000 url(" + meta.poster + ") no-repeat center center"
      self.player.style.backgroundSize = "100% auto"
      self.video.preload = "none"
    if self.meta.title
      title = create("div", self.info, "youtube5title youtube5show-on-waiting")
      link = create("a", title)
      link.textContent = self.meta.title
      link.href = self.meta.link
    if self.meta.author
      author = create("div", self.info, "youtube5author youtube5show-on-waiting")
      author.textContent = "By "
      link = create("a", author)
      link.textContent = self.meta.author
      link.href = self.meta.authorLink
    self.formats = create("div", self.info, "youtube5formats")
    self.from = create("div", self.formats, "youtube5from")
    self.from.textContent = self.meta.from
    self.formatList = create("ul", self.formats)
    for name of self.meta.formats
      format = create("li", self.formatList)
      link = create("a", format)
      link.textContent = name
      link.href = self.meta.formats[name]
      link.addEventListener "click", self.changeQuality, false
      format.className = "youtube5current-format"  if meta.useFormat is name
    self.replay = create("div", self.info, "youtube5replay")
    self.replay.innerHTML = "&larr; Replay"
    self.closeOverlay = create("div", self.info, "youtube5close-overlay")
    self.closeOverlay.textContent = "X"
    self.infoButton = create("div", self.player, "youtube5info-button")
    self.infoButton.textContent = "i"
    unless self.meta.autoplay
      self.playLarge = create("div", self.player, "youtube5play-large")
      self.playLarge.addEventListener "click", (->
        self.playOrPause()
      ), false
    self.video.addEventListener "loadedmetadata", self.initVideo, false
    self.video.addEventListener "canplay", self.videoReady, false
    self.infoButton.addEventListener "click", self.showOverlay, false
    self.info.addEventListener "click", ((event) ->
      self.playOrPause()  if event.target is self.info
    ), false
    self.replay.addEventListener "click", (->
      self.playOrPause()
      self.hideOverlay()
      removeClass self.player, "youtube5replay"
    ), false
    self.closeOverlay.addEventListener "click", self.hideOverlay, false
    self.video.addEventListener "ended", (->
      self.video.pause()
      self.showOverlay()
      addClass self.player, "youtube5replay"
    ), false

  self.createControls = ->
    removeClass self.player, "youtube5loading"
    removeClass self.player, "youtube5waiting"
    self.controls = create("div", self.player, "youtube5controls")

    # if the video is already playing, we need to set the right classname
    self.controls.className = "youtube5controls youtube5play"  unless self.video.paused
    self.playPause = create("div", self.controls, "youtube5play-pause")
    self.timeElapsed = create("div", self.controls, "youtube5time-elapsed")
    self.progress = create("div", self.controls, "youtube5progress")
    self.nudge = create("div", self.progress, "youtube5progressnudge")
    self.loaded = create("div", self.nudge, "youtube5loaded")
    self.played = create("div", self.nudge, "youtube5played")
    self.position = create("input", self.progress, "youtube5position")
    self.position.type = "range"
    self.position.min = 0
    self.position.max = 1000
    self.position.value = 0
    self.timeRemaining = create("div", self.controls, "youtube5time-remaining")
    self.volume = create("div", self.controls, "youtube5volume")
    create "div", self.volume, "youtube5volume-indicator"
    self.volumePopup = create("div", self.volume, "youtube5volume-popup")
    self.volumeMax = create("div", self.volumePopup, "youtube5volume-max")
    self.volumeSlider = create("input", self.volumePopup, "youtube5volume-slider")
    self.volumeSlider.type = "range"
    self.volumeSlider.min = 0
    self.volumeSlider.max = 100
    self.volumeSlider.value = 100
    self.volumeMute = create("div", self.volumePopup, "youtube5volume-mute")
    self.popOut = create("div", self.controls, "youtube5pop-out")
    self.fullscreen = create("div", self.controls, "youtube5fullscreen")
    self.playPause.addEventListener "click", self.playOrPause, false
    self.popOut.addEventListener "click", self.popInOrOut, false
    self.fullscreen.addEventListener "click", self.toggleFullScreen, false
    self.volumeSlider.addEventListener "change", (->
      self.setVolume self.volumeSlider.value / 100
    ), false
    self.volumeMax.addEventListener "click", (->
      self.setVolume 1
      self.updateVolumeSlider()
    ), false
    self.volumeMute.addEventListener "click", (->
      self.setVolume 0
      self.updateVolumeSlider()
    ), false
    self.position.addEventListener "change", self.seek, false
    self.video.addEventListener "progress", self.updateLoaded, false
    self.video.addEventListener "timeupdate", self.updatePosition, false
    self.video.addEventListener "volumechange", self.updateVolumeSlider, false
    self.video.addEventListener "play", (->
      self.controls.className = "youtube5controls youtube5play"
    ), false
    self.video.addEventListener "pause", (->
      self.controls.className = "youtube5controls youtube5pause"
    ), false

    # fullscreen handler
    document.addEventListener "webkitfullscreenchange", ((event) ->
      if document.webkitIsFullScreen
        addClass self.player, "youtube5fullscreened"
      else
        removeClass self.player, "youtube5fullscreened"
    ), false

    # keyboard shortcuts
    document.addEventListener "keypress", ((event) ->
      if event.target is document.body and focusedPlayer is self and not event.shiftKey and not event.altKey and not event.ctrlKey and not event.metaKey
        if event.keyCode is 32 # space = play/pause
          event.preventDefault()
          self.playOrPause()
        else if event.keyCode is 102 # f = fullscreen
          event.preventDefault()
          self.toggleFullScreen()
        else if event.keyCode is 112 # p = popout
          event.preventDefault()
          self.popInOrOut()
    ), false
    document.addEventListener "keydown", ((event) ->
      if event.target is document.body and focusedPlayer is self and not event.altKey and not event.ctrlKey and not event.metaKey
        if event.keyCode is 37 # left arrow = back five seconds
          event.preventDefault()
          if event.shiftKey
            if self.video.currentTime > 1
              self.video.currentTime -= 1
            else
              self.video.currentTime = 0
          else
            if self.video.currentTime > 5
              self.video.currentTime -= 5
            else
              self.video.currentTime = 0
        else if event.keyCode is 39 # right arrow = forward five seconds
          event.preventDefault()
          if event.shiftKey
            if self.video.currentTime < self.video.duration - 1
              self.video.currentTime += 1
            else
              self.video.currentTime = self.video.duration
          else
            if self.video.currentTime < self.video.duration - 5
              self.video.currentTime += 5
            else
              self.video.currentTime = self.video.duration
    ), false

    # timecode link handling
    document.addEventListener "click", ((event) ->
      if event.target.nodeName.toLowerCase() is "a" and focusedPlayer is self
        match = /^(?:(\d+):)?(\d{1,2}):(\d{2})$/.exec(event.target.textContent)
        if match
          event.preventDefault()
          seconds = 0
          [
            3600
            60
            1
          ].forEach (multiplier, i) ->
            timeValue = parseInt(match[i + 1])
            seconds += multiplier * timeValue  if timeValue

          self.video.currentTime = seconds
          self.container.scrollIntoView()
    ), false

  self
