newFacebook = ->
  self = newProvider()
  self.videoUrlPatterns = [/\/rsrc.php\/.*\.swf/i]
  self.canLoadVideo = (requestInfo) ->
    self.videoUrlPatterns.some (pattern) ->
      pattern.test(requestInfo.url) and requestInfo.flashvars.indexOf("thumbnail_src") isnt -1

  self.enabled = ->
    isProviderEnabled 'facebook'

  self.loadVideo = (requestInfo, callback) ->
    if self.videoUrlPatterns[0].test(requestInfo.url)
      data = parseUrlEncoded(requestInfo.flashvars)
      meta = self.processMeta(data, event)
      callback meta

  self.processMeta = (data, event) ->
    meta = {}
    params = JSON.parse(data.params)
    video_data = params.video_data[0]

    meta.formats = []
    if video_data.hd_src
      meta.formats.push
        height: 720
        width: 1280
        name: 'HD'
        url: video_data.hd_src
    meta.formats.push
      height: 360
      width: 640
      name: 'SD'
      url: video_data.sd_src

    meta.title = "Facebook video"
    meta.poster = video_data.thumbnail_src
    meta.link = params.permalink_url
    meta.from = "Facebook"
    meta.autoplay = params.autoplay
    meta

  self

providers.push newFacebook()
