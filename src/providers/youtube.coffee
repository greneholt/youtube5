newYouTube = ->
  self = newProvider()
  self.videoUrlPatterns = [
    /^https?:\/\/(?:www\.)?youtube(?:\-nocookie)?\.com\/(?:v|embed)\/([^\?&]+)(?:[\?&](.+))?/i
    /^https?:\/\/s.ytimg.com\/yts?\/swf(?:bin)?\/watch/i
  ]
  self.blockScriptUrlPatterns = [/^https?:\/\/s.ytimg.com\/yts?\/jsbin\/html5player-.+\.js$/]
  self.enabled = ->
    isProviderEnabled 'youtube'

  self.loadVideo = (requestInfo, callback) ->
    match = requestInfo.url.match(self.videoUrlPatterns[0])
    if match
      videoId = match[1]
      params = parseUrlEncoded(match[2])
      self.startLoad videoId, (params.autoplay and params.autoplay isnt "0"), getStartTime(params), requestInfo.flashvars, callback
      true
    else if self.videoUrlPatterns[1].test(requestInfo.url)
      data = parseUrlEncoded(requestInfo.flashvars)
      self.startLoad data.video_id, true, null, data, callback
      true
    else
      false

  self.signatureDecipher =
    timestamp: 15992
    clone: (a, b) ->
      a.slice b

    decipher: (s) ->
      t = s.split ""
      t = @swap(t, 2)
      t = @reverse(t)
      t = @clone(t, 3)
      t = @swap(t, 52)
      t = @clone(t, 2)
      t = @swap(t, 63)
      t = @clone(t, 2)
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
      18: {height: 360, width: 640, name: "360p"}
      22: {height: 720, width: 1280, name: "720p"}
      37: {height: 1080, width: 1920, name: "1080p"}
      38: {height: 2160, width: 3840, name: "Original (4k)"}

    meta.formats = []
    for format in (data.url_encoded_fmt_stream_map or (flashvars and flashvars.url_encoded_fmt_stream_map)).split(',')
      tmp = parseUrlEncoded(format)
      if format = youtubeFormats[tmp.itag]
        url = tmp.url + "&title=" + encodeURIComponent(data.title)
        if tmp.sig
          url += "&signature=" + encodeURIComponent(tmp.sig)
        else if tmp.s
          url += "&signature=" + encodeURIComponent(self.signatureDecipher.decipher(tmp.s))
        format = shallowClone(format)
        format.url = url
        meta.formats.push format

    if data.iurlmaxres
      meta.poster = data.iurlmaxres
    else if data.iurlsd
      meta.poster = data.iurlsd
    else if data.thumbnail_url
      meta.poster = data.thumbnail_url.replace(/default.jpg/, "hqdefault.jpg")

    meta.title = data.title
    meta.author = data.author
    meta.authorLink = "https://www.youtube.com/user/" + data.author
    meta.link = "https://www.youtube.com/watch?v=" + data.video_id
    meta.from = "YouTube"
    meta

  self.startLoad = (videoId, autoplay, startTime, flashvars, callback) ->
    req = new XMLHttpRequest()
    req.open "GET", "https://www.youtube.com/get_video_info?&video_id=#{videoId}&eurl=http%3A%2F%2Fwww%2Eyoutube%2Ecom%2F&asv=3&sts=#{self.signatureDecipher.timestamp}", true
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
