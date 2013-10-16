newVimeo = ->
  self = newProvider()
  self.videoUrlPatterns = [
    /^https?:\/\/assets\.vimeo\.com\/flash\/moog/i
    /vimeo\.com\/moogaloop\.swf?.*clip_id=(\d+)/i
    /vimeo.*\/moogaloop/i
    /^https?:\/\/player.vimeo.com\/video\/(\d+)/i
  ]
  self.enabled = ->
    isProviderEnabled 'vimeo'

  self.loadVideo = (requestInfo, callback) ->
    if (m = requestInfo.url.match(self.videoUrlPatterns[1])) or (m = requestInfo.url.match(self.videoUrlPatterns[3]))
      clipId = m[1]
      self.startLoad clipId, false, callback
      true
    else if self.videoUrlPatterns[0].test(requestInfo.url) or self.videoUrlPatterns[2].test(requestInfo.url)
      data = parseUrlEncoded(requestInfo.flashvars)
      self.startLoad data.clip_id, false, callback
      true
    else
      false

  self.processMeta = (clipId, text) ->
    meta = {}

    m = text.match(/c=(\{"cdn_url"[\s\S]*?\});/i) # dotall doesn't exist in JS, so use [\s\S]

    unless m
      meta.error = 'Invalid meta for Vimeo'
      return meta

    data = JSON.parse m[1]
    meta.formats = []
    for name, format of data.request.files.h264
      meta.formats.push
        name: name
        width: format.width
        height: format.height
        url: format.url

    posterSize = null
    for size, url of data.video.thumbs
      size = parseInt size
      if !posterSize or size > posterSize
        meta.poster = url
        posterSize = size

    meta.title = data.video.title
    meta.author = data.video.owner.name
    meta.authorLink = data.video.owner.url
    meta.link = data.video.url
    meta.from = "Vimeo"
    meta

  self.startLoad = (clipId, autoplay, callback) ->
    req = new XMLHttpRequest()
    req.open "GET", "http://player.vimeo.com/video/" + clipId, true
    req.onreadystatechange = (ev) ->
      if req.readyState is 4 and req.status is 200
        meta = self.processMeta(clipId, req.responseText)
        meta.autoplay = autoplay
        callback meta
      else if req.readyState is 4 and req.status is 404
        meta = error: "404 Error loading Vimeo video"
        callback meta

    req.send null

  self

providers.push newVimeo()
