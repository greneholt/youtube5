var newYouTube = function() {
	var self = newProvider();

	self.urlPatterns = [
		/^https?:\/\/(?:www\.)?youtube(?:\-nocookie)?\.com\/(?:v|embed)\/([^\?&]+)(?:[\?&](.+))?/i,
		/^https?:\/\/s.ytimg.com\/yts?\/swf(?:bin)?\/watch/i
	];

	self.enabled = function() {
		return safari.extension.settings.enableYouTube;
	};

	self.loadVideo = function(url, playerId, flashvars, event) {
		var match = url.match(self.urlPatterns[0]);

		if (match) {
			var videoId = match[1];
			var params = parseUrlEncoded(match[2]);
			self.startLoad(playerId, videoId, params.autoplay && params.autoplay != '0', getStartTime(params), event, flashvars);
			return true;
		}
		else if (self.urlPatterns[1].test(url)) {
			var data = parseUrlEncoded(flashvars);
			self.startLoad(playerId, data.video_id, safari.extension.settings.youTubeAutoplay, null, event, data);
			return true;
		}
		else {
			return false;
		}
	};

	self.processMeta = function(text, flashvars) {
		var meta = {};

		var data = parseUrlEncoded(text);

		if (data.errorcode && (!flashvars || !flashvars.url_encoded_fmt_stream_map)) {
			meta.error = data.reason;
			return meta;
		}

		/*
		Format Reference

		5 - FLV 240p
		18 - MP4 360p
		22 - MP4 720p (HD)
		34 - FLV 360p
		35 - FLV 480p
		37 - MP4 1080p (HD)
		38 - MP4 Original (HD)
		43 - WebM 480p
		45 - WebM 720p (HD)
		*/

		var youTubeFormats = { 5: '240p FLV', 18: '360p', 22: '720p', 37: '1080p', 38: 'Original (4k)' };

		meta.formats = {};
		((flashvars && flashvars.url_encoded_fmt_stream_map) || data.url_encoded_fmt_stream_map).split(',').forEach(function(format) {
			var tmp = parseUrlEncoded(format);
			if (youTubeFormats[tmp.itag]) {
				meta.formats[youTubeFormats[tmp.itag]] = tmp.url + "&signature=" + tmp.sig;
			}
		});

		var defaultFormat = safari.extension.settings.youTubeFormat;
		if (meta.formats[defaultFormat]) {
			meta.useFormat = defaultFormat;
		} else {
			for (format in meta.formats) {
				if (parseInt(format) < parseInt(defaultFormat) && (!meta.useFormat || parseInt(format) > parseInt(meta.useFormat))) {
					meta.useFormat = format;
				} else {
					break;
				}
			}
		}

		if (data.thumbnail_url) {
			meta.poster = data.thumbnail_url.replace(/default.jpg/, 'hqdefault.jpg');
		}
		meta.title = data.title;
		meta.author = data.author;
		meta.authorLink = 'https://www.youtube.com/user/' + data.author;
		meta.link = 'https://www.youtube.com/watch?v=' + data.video_id;
		meta.from = 'YouTube';

		return meta;
	};

	self.startLoad = function(playerId, videoId, autoplay, startTime, event, flashvars) {
		var req = new XMLHttpRequest();
		req.open('GET', 'https://www.youtube.com/get_video_info?&video_id=' + videoId + '&el=embedded&ps=default&eurl=http%3A%2F%2Fwww%2Egoogle%2Ecom%2F&hl=en_US', true);
		req.onreadystatechange = function(ev) {
			if (req.readyState === 4 && req.status === 200) {
				var meta = self.processMeta(req.responseText, flashvars);
				meta.autoplay = autoplay;
				meta.startTime = startTime;
				injectVideo(event, playerId, meta);
			} else if (req.readyState === 4 && req.status === 404) {
				var meta = { error: '404 Error loading YouTube video' };
				injectVideo(event, playerId, meta);
			}
		};
		req.send(null);
	};

	return self;
};

providers.push(newYouTube());