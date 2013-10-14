newYouTube = ->
  self = newProvider()
  self.videoUrlPatterns = [
    /^https?:\/\/(?:www\.)?youtube(?:\-nocookie)?\.com\/(?:v|embed)\/([^\?&]+)(?:[\?&](.+))?/i
    /^https?:\/\/s.ytimg.com\/yts?\/swf(?:bin)?\/watch/i
  ]
  self.blockScriptUrlPatterns = [/^https?:\/\/s.ytimg.com\/yts?\/jsbin\/html5player-.+\.js$/]
  self.enabled = ->
    getPreference('enableYoutube')

  self.loadVideo = (url, flashvars, callback) ->
    match = url.match(self.videoUrlPatterns[0])
    if match
      videoId = match[1]
      params = parseUrlEncoded(match[2])
      self.startLoad videoId, (params.autoplay and params.autoplay isnt "0"), getStartTime(params), flashvars, callback
      true
    else if self.videoUrlPatterns[1].test(url)
      data = parseUrlEncoded(flashvars)
      self.startLoad data.video_id, getPreference('youtubeAutoplay'), null, data, callback
      true
    else
      false

  self.signatureDecipher =
    timestamp: 15902
    clone: (a, b) ->
      a.slice b

    decipher: (s) ->
      t = s.split("")
      t = @clone(t, 2)
      t = @reverse(t)
      t = @clone(t, 3)
      t = @swap(t, 9)
      t = @clone(t, 3)
      t = @swap(t, 43)
      t = @clone(t, 3)
      t = @reverse(t)
      t = @swap(t, 23)
      t.join ""

    swap: (a, b) ->
      t1 = a[0]
      t2 = a[(b % a.length)]
      a[0] = t2
      a[b] = t1
      a

    reverse: (a) ->
      a.reverse()
      a

  self.processMeta = (text, flashvars) ->
    meta = {}
    data = parseUrlEncoded(text)
    if data.errorcode and (not flashvars or not flashvars.url_encoded_fmt_stream_map)
      meta.error = data.reason
      return meta

		# Format Reference

		# 5 - FLV 240p
		# 18 - MP4 360p
		# 22 - MP4 720p (HD)
		# 34 - FLV 360p
		# 35 - FLV 480p
		# 37 - MP4 1080p (HD)
		# 38 - MP4 Original (HD)
		# 43 - WebM 480p
		# 45 - WebM 720p (HD)

    youtubeFormats =
      5: "240p FLV"
      18: "360p"
      22: "720p"
      37: "1080p"
      38: "Original (4k)"

    meta.formats = {}
    (data.url_encoded_fmt_stream_map or (flashvars and flashvars.url_encoded_fmt_stream_map)).split(",").forEach (format) ->
      tmp = parseUrlEncoded(format)
      if youtubeFormats[tmp.itag]
        url = tmp.url + "&title=" + encodeURIComponent(data.title)
        if tmp.sig
          url += "&signature=" + encodeURIComponent(tmp.sig)
        else url += "&signature=" + encodeURIComponent(self.signatureDecipher.decipher(tmp.s))  if tmp.s
        meta.formats[youtubeFormats[tmp.itag]] = url

    defaultFormat = getPreference('youtubeFormat')
    if meta.formats[defaultFormat]
      meta.useFormat = defaultFormat
    else
      for format of meta.formats
        if parseInt(format) < parseInt(defaultFormat) and (not meta.useFormat or parseInt(format) > parseInt(meta.useFormat))
          meta.useFormat = format
        else
          break
    if data.iurlmaxres
      meta.poster = data.iurlmaxres
    else if data.iurlsd
      meta.poster = data.iurlsd
    else meta.poster = data.thumbnail_url.replace(/default.jpg/, "hqdefault.jpg")  if data.thumbnail_url
    meta.title = data.title
    meta.author = data.author
    meta.authorLink = "https://www.youtube.com/user/" + data.author
    meta.link = "https://www.youtube.com/watch?v=" + data.video_id
    meta.from = "YouTube"
    meta

  self.startLoad = (videoId, autoplay, startTime, flashvars, callback) ->
    req = new XMLHttpRequest()
    req.open "GET", "https://www.youtube.com/get_video_info?&video_id=" + videoId + "&eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F&asv=3&sts=" + self.signatureDecipher.timestamp, true
    req.onreadystatechange = (ev) ->
      if req.readyState is 4 and req.status is 200
        meta = self.processMeta(req.responseText, flashvars)
        meta.autoplay = autoplay
        meta.startTime = startTime
        callback meta
      else if req.readyState is 4 and req.status is 404
        meta = error: "404 Error loading YouTube video"
        callback meta

    req.send null

  self

providers.push newYouTube()
