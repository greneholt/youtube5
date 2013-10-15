focusedPlayer = null

class Player
  floating: false
  hovered: false
  hoverTimeoutId: null

  constructor: (replace, @width, @height) ->
    @originalPlayer = replace

    @placeholder = document.createElement("div")
    @placeholder.className = "youtube5placeholder"
    @placeholder.style.width = @width + "px"
    @placeholder.style.height = @height + "px"
    @placeholder.setAttribute "data-clean", "yes" # prevent Feedly from stripping style attributes

    @container = create("div", @placeholder, "youtube5container")
    @container.style.width = @width + "px"
    @container.style.height = @height + "px"
    @container.style.position = "relative"
    @container.style.margin = "0 auto"

    @player = create("div", @container, "youtube5player youtube5loading")
    @player.style.width = "100%"
    @player.style.height = "100%"

    @topOverlay = create("div", @player, "youtube5top-overlay")
    @bottomOverlay = create("div", @player, "youtube5bottom-overlay")

    @info = create("div", @player, "youtube5info")

    @useOriginal = create("div", @info, "youtube5use-original youtube5show-on-waiting")
    @useOriginal.innerHTML = "&crarr; Use original player"
    @useOriginal.addEventListener "click", @revert, false

    replace.parentNode.replaceChild @placeholder, replace

    @player.addEventListener "mousemove", @updateHoverTimeout, false

  revert: =>
    @placeholder.parentNode.replaceChild @originalPlayer, @placeholder

  updateHoverTimeout: =>
    unless @hovered
      @hovered = true
      addClass @player, "youtube5hover"
    else if @hoverTimeoutId isnt null
      window.clearTimeout @hoverTimeoutId
    @hoverTimeoutId = window.setTimeout(@unHover, 2000)

  unHover: =>
    @hovered = false
    # we need to temporarily disable the mousemove event listener because
    # for some reason safari fires a mousemove event when the cursor is changed.
    # https://bugs.webkit.org/show_bug.cgi?id=85343
    @player.removeEventListener "mousemove", @updateHoverTimeout, false
    window.setTimeout @unHoverTransitionComplete, 500
    removeClass @player, "youtube5hover"
    @hoverTimeoutId = null

  unHoverTransitionComplete: =>
    @player.addEventListener "mousemove", @updateHoverTimeout, false

  updatePlayerSize: =>
    if @floating
      width = @video.videoWidth
      height = @video.videoHeight
      minWidth = window.innerWidth * 0.8
      minHeight = window.innerHeight * 0.8
      if width > window.innerWidth
        width = window.innerWidth
      else if width < minWidth
        width = minWidth

      if height > window.innerHeight
        height = window.innerHeight
      else if height < minHeight
        height = minHeight
    else
      width = @width
      height = @height

    realAspectRatio = width / height
    nativeAspectRatio = @video.videoWidth / @video.videoHeight

    # if the player is wider than necessary, fit by height
    if realAspectRatio > nativeAspectRatio
      width = Math.round(height * nativeAspectRatio)
      height = height
    else # taller than necessary
      width = width
      height = Math.round(width / nativeAspectRatio)

    @container.style.width = width + "px"
    @container.style.height = height + "px"
    return [width, height]

  updateTime: =>
    remaining = @video.duration - @video.currentTime
    @timeElapsed.textContent = formatTime(@video.currentTime)
    @timeRemaining.textContent = "-" + formatTime(remaining)

  updatePlayed: =>
    @played.style.width = @position.value / 10 + "%"

  updateLoaded: =>
    return if isNaN(@video.duration) or @video.buffered.length is 0
    @loaded.style.width = @video.buffered.end(0) / @video.duration * 100 + "%"

  updatePosition: =>
    return if isNaN(@video.duration)
    @position.value = @video.currentTime / @video.duration * 1000
    @updatePlayed()
    @updateTime()

  updateVolumeSlider: =>
    @volumeSlider.value = @video.volume * 100
    @updateVolumeIndicator()

  updateVolumeIndicator: =>
    if @video.volume > 0.75
      @volume.className = "youtube5volume youtube5high"
    else if @video.volume > 0.3
      @volume.className = "youtube5volume youtube5med"
    else if @video.volume > 0.02
      @volume.className = "youtube5volume youtube5low"
    else
      @volume.className = "youtube5volume youtube5off"

  seek: =>
    return if isNaN(@video.duration)
    @video.currentTime = @position.value / 1000 * @video.duration
    @updatePlayed()
    @hideOverlay()

  showOverlay: =>
    addClass @player, "youtube5overlayed"

  hideOverlay: =>
    removeClass @player, "youtube5overlayed"

  playOrPause: =>
    if @video.paused
      if hasClass(@player, "youtube5waiting")
        removeClass @player, "youtube5waiting"
        addClass @player, "youtube5loading"
      @video.play()
      @removePlayLarge()
      @hideOverlay()
    else
      @video.pause()

    focusedPlayer = this # set the focused player to this one

  popInOrOut: =>
    return if document.webkitIsFullScreen
    transitionCss = "width 0.5s ease-out, height 0.5s ease-out, left 0.5s ease-out, top 0.5s ease-out"
    if @floating
      @floating = false
      position = findPosition(@container)

      # setup the starting point of the animation
      @container.style.left = position[0] + "px"
      @container.style.top = position[1] + "px"
      @container.style.margin = "0 auto"
      @container.offsetWidth # Force reflow hack. Makes the animation use the proper start positions.

      # enable the transition animation before making changes
      @container.style.webkitTransition = transitionCss
      @updatePlayerSize()
      @container.style.left = @originalPosition[0] + "px"
      @container.style.top = @originalPosition[1] + "px"
      @container.addEventListener "webkitTransitionEnd", @dockedTransitionComplete, false
    else
      @floating = true
      @originalPosition = findPosition(@container)

      # when we change its dom position, the video stops playing
      paused = @video.paused
      document.body.appendChild @container
      @video.play()  unless paused

      # setup the starting point of the animation
      @container.style.position = "absolute"
      @container.style.left = @originalPosition[0] + "px"
      @container.style.top = @originalPosition[1] + "px"
      @container.style.zIndex = 100000
      @container.style.webkitBoxShadow = "0 0 20px #000"
      ignore = @container.offsetWidth # Force reflow hack. Makes the animation use the proper start positions.

      # enable the transition animation before making changes
      @container.style.webkitTransition = transitionCss
      size = @updatePlayerSize()
      newWidth = size[0]
      newHeight = size[1]
      @container.style.left = document.body.scrollLeft + (window.innerWidth - newWidth) / 2 + "px"
      @container.style.top = document.body.scrollTop + (window.innerHeight - newHeight) / 2 + "px"
      @container.addEventListener "webkitTransitionEnd", @floatingTransitionComplete, false

  toggleFullScreen: =>
    if document.webkitIsFullScreen
      document.webkitCancelFullScreen()
    else
      @player.webkitRequestFullScreen()

  floatingTransitionComplete: (event) =>
    return unless event.propertyName is "left" # don't allow the animation to be short circuited by other transitions completing
    @container.style.webkitTransition = null
    @container.style.left = "50%"
    @container.style.margin = "0 0 0 " + -@container.clientWidth / 2 + "px"
    @container.removeEventListener "webkitTransitionEnd", @floatingTransitionComplete, false

  dockedTransitionComplete: (event) =>
    return unless event.propertyName is "left" # don't allow the animation to be short circuited by other transitions completing
    @container.style.webkitTransition = null
    paused = @video.paused
    @placeholder.appendChild @container
    @video.play()  unless paused

    # reset all the styles we changed
    @container.style.position = "relative"
    @container.style.left = null
    @container.style.top = null
    @container.style.zIndex = null
    @container.style.webkitBoxShadow = null
    @container.removeEventListener "webkitTransitionEnd", @dockedTransitionComplete, false

  removePlayLarge: =>
    if @playLarge
      @player.style.background = null
      @player.style.backgroundSize = null
      @player.removeChild @playLarge
      @playLarge = null

  setVolume: (volume) =>
    @video.muted = volume < 0.02
    @video.volume = volume
    @updateVolumeIndicator()
    @meta.volumeCallback volume if @meta.volumeCallback

  changeQuality: (event) =>
    event.preventDefault()
    format = event.target.textContent
    paused = @video.paused
    @video.src = @meta.formats[format]

    # only load the video if its already been playing
    @video.preload = "auto" if @controls
    @video.play() unless paused
    nodes = event.target.parentNode.parentNode.childNodes
    for node in nodes
      node.className = ""
    event.target.parentNode.className = "youtube5current-format"

  initVideo: =>
    @video.currentTime = @meta.startTime if @meta.startTime
    @updatePlayerSize()
    @video.removeEventListener "loadedmetadata", @initVideo, false

  videoReady: =>
    @video.removeEventListener "canplay", @videoReady, false
    @createControls()
    @updatePosition()
    @updateLoaded()
    @setVolume @meta.volume
    @video.addEventListener "loadedmetadata", (=>
      console.log 'loaded new video'
      @seek()
      @updateTime()
    ), false

  loadStartTime: =>
    hashData = parseUrlEncoded(document.location.hash.replace(/^#/, ""))
    searchData = parseUrlEncoded(document.location.search.replace(/^\?/, ""))
    for attr of hashData
      searchData[attr] = hashData[attr]
    startTime = getStartTime(searchData)
    @meta.startTime = startTime if startTime

  injectVideo: (meta) =>
    # don't allow injecting the video twice
    return if @meta
    @meta = meta

    if @meta.error
      @player.className = "youtube5player error"
      @error = create("div", @player, "youtube5error")
      @error.innerHTML = @meta.error
      return

    @loadStartTime()
    @video = document.createElement("video")
    @video.src = meta.formats[meta.useFormat]
    @player.insertBefore @video, @topOverlay

    if @meta.autoplay
      focusedPlayer = this
      @playOrPause()
    else
      removeClass @player, "youtube5loading"
      addClass @player, "youtube5waiting"
      @player.style.background = "#000 url(" + meta.poster + ") no-repeat center center"
      @player.style.backgroundSize = "100% auto"
      @video.preload = "none"

    if @meta.title
      title = create("div", @info, "youtube5title youtube5show-on-waiting")
      link = create("a", title)
      link.textContent = @meta.title
      link.href = @meta.link

    if @meta.author
      author = create("div", @info, "youtube5author youtube5show-on-waiting")
      author.textContent = "By "
      link = create("a", author)
      link.textContent = @meta.author
      link.href = @meta.authorLink

    @formats = create("div", @info, "youtube5formats")
    @from = create("div", @formats, "youtube5from")
    @from.textContent = @meta.from

    @formatList = create("ul", @formats)
    for name, url of @meta.formats
      format = create("li", @formatList)
      link = create("a", format)
      link.textContent = name
      link.href = url
      link.addEventListener "click", @changeQuality, false
      format.className = "youtube5current-format" if meta.useFormat is name

    @replay = create("div", @info, "youtube5replay")
    @replay.innerHTML = "&larr; Replay"

    @closeOverlay = create("div", @info, "youtube5close-overlay")
    @closeOverlay.textContent = "X"

    @infoButton = create("div", @player, "youtube5info-button")
    @infoButton.textContent = "i"

    unless @meta.autoplay
      @playLarge = create("div", @player, "youtube5play-large")
      @playLarge.addEventListener "click", @playOrPause, false

    @video.addEventListener "loadedmetadata", @initVideo, false
    @video.addEventListener "canplay", @videoReady, false

    @infoButton.addEventListener "click", @showOverlay, false

    @info.addEventListener "click", ((event) =>
      @playOrPause() if event.target is @info
    ), false

    @replay.addEventListener "click", (=>
      @playOrPause()
      @hideOverlay()
      removeClass @player, "youtube5replay"
    ), false

    @closeOverlay.addEventListener "click", @hideOverlay, false

    @video.addEventListener "ended", (=>
      @video.pause()
      @showOverlay()
      addClass @player, "youtube5replay"
    ), false

  createControls: =>
    removeClass @player, "youtube5loading"
    removeClass @player, "youtube5waiting"

    # create controls
    @controls = create("div", @player, "youtube5controls")

    # if the video is already playing, we need to set the right classname
    @controls.className = "youtube5controls youtube5play" unless @video.paused
    @playPause = create("div", @controls, "youtube5play-pause")
    @timeElapsed = create("div", @controls, "youtube5time-elapsed")
    @progress = create("div", @controls, "youtube5progress")
    @nudge = create("div", @progress, "youtube5progressnudge")
    @loaded = create("div", @nudge, "youtube5loaded")
    @played = create("div", @nudge, "youtube5played")
    @position = create("input", @progress, "youtube5position")
    @position.type = "range"
    @position.min = 0
    @position.max = 1000
    @position.value = 0
    @timeRemaining = create("div", @controls, "youtube5time-remaining")
    @volume = create("div", @controls, "youtube5volume")
    create "div", @volume, "youtube5volume-indicator"
    @volumePopup = create("div", @volume, "youtube5volume-popup")
    @volumeMax = create("div", @volumePopup, "youtube5volume-max")
    @volumeSlider = create("input", @volumePopup, "youtube5volume-slider")
    @volumeSlider.type = "range"
    @volumeSlider.min = 0
    @volumeSlider.max = 100
    @volumeSlider.value = 100
    @volumeMute = create("div", @volumePopup, "youtube5volume-mute")
    @popOut = create("div", @controls, "youtube5pop-out")
    @fullscreen = create("div", @controls, "youtube5fullscreen")

    # setup event listeners
    @playPause.addEventListener "click", @playOrPause, false
    @popOut.addEventListener "click", @popInOrOut, false
    @fullscreen.addEventListener "click", @toggleFullScreen, false
    @volumeSlider.addEventListener "change", (=>
      @setVolume @volumeSlider.value / 100
    ), false
    @volumeSlider.addEventListener "focus", => # prevent slider from keeping focus, messing up keyboard control
      @volumeSlider.blur()
    , false
    @volumeMax.addEventListener "click", (=>
      @setVolume 1
      @updateVolumeSlider()
    ), false
    @volumeMute.addEventListener "click", (=>
      @setVolume 0
      @updateVolumeSlider()
    ), false
    @position.addEventListener "change", @seek, false
    @position.addEventListener "focus", => # prevent from keeping focus
      @position.blur()
    , false
    @video.addEventListener "progress", @updateLoaded, false
    @video.addEventListener "timeupdate", @updatePosition, false
    @video.addEventListener "volumechange", @updateVolumeSlider, false
    @video.addEventListener "play", (=>
      @controls.className = "youtube5controls youtube5play"
    ), false
    @video.addEventListener "pause", (=>
      @controls.className = "youtube5controls youtube5pause"
    ), false

    # fullscreen handler
    document.addEventListener "webkitfullscreenchange", ((event) =>
      if document.webkitIsFullScreen
        addClass @player, "youtube5fullscreened"
      else
        removeClass @player, "youtube5fullscreened"
    ), false

    # keyboard shortcuts
    document.addEventListener "keypress", ((event) =>
      if event.target is document.body and focusedPlayer is this and not event.shiftKey and not event.altKey and not event.ctrlKey and not event.metaKey
        if event.keyCode is 32 # space = play/pause
          event.preventDefault()
          @playOrPause()
        else if event.keyCode is 102 # f = fullscreen
          event.preventDefault()
          @toggleFullScreen()
        else if event.keyCode is 112 # p = popout
          event.preventDefault()
          @popInOrOut()
    ), false

    document.addEventListener "keydown", ((event) =>
      if event.target is document.body and focusedPlayer is this and not event.altKey and not event.ctrlKey and not event.metaKey
        if event.keyCode is 37 # left arrow = back five seconds
          event.preventDefault()
          if event.shiftKey
            if @video.currentTime > 1
              @video.currentTime -= 1
            else
              @video.currentTime = 0
          else
            if @video.currentTime > 5
              @video.currentTime -= 5
            else
              @video.currentTime = 0
        else if event.keyCode is 39 # right arrow = forward five seconds
          event.preventDefault()
          if event.shiftKey
            if @video.currentTime < @video.duration - 1
              @video.currentTime += 1
            else
              @video.currentTime = @video.duration
          else
            if @video.currentTime < @video.duration - 5
              @video.currentTime += 5
            else
              @video.currentTime = @video.duration
    ), false

    # timecode link handling
    document.addEventListener "click", ((event) =>
      if event.target.nodeName.toLowerCase() is "a" and focusedPlayer is this
        seconds = parseTimeCode(event.target.textContent)
        if seconds
          @video.currentTime = seconds
          @container.scrollIntoView()
    ), false