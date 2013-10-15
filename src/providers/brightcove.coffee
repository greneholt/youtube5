newBrightcove = ->
  self = newProvider()
  self.videoUrlPatterns = [/brightcove\.com\/services\/viewer\//i]
  self.enabled = ->
    isProviderEnabled 'brightcove'

  self.loadVideo = (requestInfo, callback) ->
    if self.videoUrlPatterns[0].test(requestInfo.url)
      self.startLoad requestInfo.url.replace(/\/viewer\/\w+(?:\.swf)?\?/i, "/viewer/htmlFederated?"), callback
      true
    else
      false

  self.processMeta = (text) ->
    meta = {}
    m = text.match(/experienceJSON = (\{.*\});/i)
    info = JSON.parse(m[1])
    if not info.data.programmedContent.videoPlayer or not info.data.programmedContent.videoPlayer.mediaDTO
      meta = error: "Not a Brightcove video"
      return meta
    video = info.data.programmedContent.videoPlayer.mediaDTO

    meta.poster = video.videoStillURL
    meta.title = video.displayName
    meta.author = video.publisherName
    meta.from = "Brightcove"

    meta.formats = for format in video.renditions
      width: format.frameWidth
      height: format.frameHeight
      name: "#{format.frameHeight}p"
      url: format.defaultURL

    meta

  self.startLoad = (url, callback) ->
    req = new XMLHttpRequest()
    req.open "GET", url, true
    req.onreadystatechange = (ev) ->
      if req.readyState is 4 and req.status is 200
        meta = self.processMeta(req.responseText)
        callback meta
      else if req.readyState is 4 and req.status is 404
        meta = error: "404 Error loading Brightcove video"
        callback meta

    req.send null

  self

providers.push newBrightcove()
