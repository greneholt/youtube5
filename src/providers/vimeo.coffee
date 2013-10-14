newVimeo = ->
  self = newProvider()
  self.videoUrlPatterns = [
    /^https?:\/\/assets\.vimeo\.com\/flash\/moog/i
    /vimeo\.com\/moogaloop\.swf?.*clip_id=(\d+)/i
    /vimeo.*\/moogaloop/i
    /^https?:\/\/player.vimeo.com\/video\/(\d+)/i
  ]
  self.enabled = ->
    safari.extension.settings.enableVimeo

  self.loadVideo = (url, playerId, flashvars, event) ->
    url = event.message.url
    if (m = url.match(self.videoUrlPatterns[1])) or (m = url.match(self.videoUrlPatterns[3]))
      clipId = m[1]
      self.startLoad playerId, clipId, false, event
      true
    else if self.videoUrlPatterns[0].test(url) or self.videoUrlPatterns[2].test(url)
      data = parseUrlEncoded(flashvars)
      self.startLoad playerId, data.clip_id, false, event
      true
    else
      false

  self.processMeta = (clipId, text) ->
    meta = {}
    m = text.match(/clip[0-9_]+ = (\{[\s\S]*\});/i) # dotall doesn't exist in JS, so use [\s\S]
    data = eval_("(" + m[1] + ")") # Vimeo doesn't use quotes always, so we can't use JSON.parse
    meta.formats = {}
    sig = data.config.request.signature
    time = data.config.request.timestamp
    data.config.video.files.h264.forEach (format) ->
      meta.formats[format.toUpperCase()] = "http://player.vimeo.com/play_redirect?quality=" + format + "&codecs=h264&clip_id=" + clipId + "&time=" + time + "&sig=" + sig + "&type=html5_desktop_local"

    defaultFormat = safari.extension.settings.vimeoFormat
    if meta.formats[defaultFormat]
      meta.useFormat = defaultFormat
    else
      meta.useFormat = "SD"
    meta.poster = data.config.video.thumbnail
    meta.title = data.config.video.title
    meta.author = data.config.video.owner.name
    meta.authorLink = data.config.video.owner.url
    meta.link = data.config.video.url
    meta.from = "Vimeo"
    meta

  self.startLoad = (playerId, clipId, autoplay, event) ->
    req = new XMLHttpRequest()
    req.open "GET", "http://player.vimeo.com/video/" + clipId, true
    req.onreadystatechange = (ev) ->
      if req.readyState is 4 and req.status is 200
        meta = self.processMeta(clipId, req.responseText)
        meta.autoplay = autoplay
        injectVideo event, playerId, meta
      else if req.readyState is 4 and req.status is 404
        meta = error: "404 Error loading Vimeo video"
        injectVideo event, playerId, meta

    req.send null

  self

providers.push newVimeo()
