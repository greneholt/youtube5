newFacebook = ->
  self = newProvider()
  self.videoUrlPatterns = [/\/rsrc.php\/.*\.swf/i]
  self.canLoadVideo = (requestInfo) ->
    self.videoUrlPatterns.some (pattern) ->
      pattern.test(requestInfo.url) and requestInfo.flashvars.indexOf("thumbnail_src") isnt -1

  self.enabled = ->
    getPreference('enableFacebook')

  self.loadVideo = (url, flashvars, callback) ->
    if self.videoUrlPatterns[0].test(url)
      data = parseUrlEncoded(flashvars)
      meta = self.processMeta(data, event)
      callback meta

  self.processMeta = (data, event) ->
    meta = {}
    params = JSON.parse(data.params)
    video_data = params.video_data[0]
    meta.formats = {}
    meta.formats["HD"] = video_data.hd_src  if video_data.hd_src
    meta.formats["SD"] = video_data.sd_src
    defaultFormat = getPreference('facebookFormat')
    if meta.formats[defaultFormat]
      meta.useFormat = defaultFormat
    else
      meta.useFormat = "SD"
    meta.title = "Facebook video"
    meta.poster = video_data.thumbnail_src
    meta.link = params.permalink_url
    meta.from = "Facebook"
    meta.autoplay = params.autoplay
    meta

  self

providers.push newFacebook()
