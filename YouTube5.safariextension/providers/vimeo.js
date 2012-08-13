var newVimeo = function() {
	var self = newProvider();

	self.urlPatterns = [
		/^https?:\/\/assets\.vimeo\.com\/flash\/moog/i,
		/vimeo\.com\/moogaloop\.swf?.*clip_id=(\d+)/i,
		/\/moogaloop/i,
		/^https?:\/\/player.vimeo.com\/video\/(\d+)/i
	];

	self.enabled = function() {
		return safari.extension.settings.enableVimeo;
	};

	self.loadVideo = function(url, playerId, flashvars, event) {
		url = event.message.url;

		if (self.urlPatterns[0].test(url) || self.urlPatterns[2].test(url)) {
			var data = parseUrlEncoded(flashvars);
			self.startLoad(playerId, data.clip_id, false, event);
			return true;
		}
		else if ((m = url.match(self.urlPatterns[1])) || (m = url.match(self.urlPatterns[3]))) {
			var clipId = m[1];
			self.startLoad(playerId, clipId, false, event);
			return true;
		}
		else {
			return false;
		}
	};

	self.processMeta = function(clipId, xml) {
		var meta = {};

		if (xml.querySelector('error')) {
			meta.error = xml.querySelector('error title').textContent + '<br />' + xml.querySelector('error message').textContent;
			return meta;
		}

		meta.formats = {};

		var sig = xml.querySelector('request_signature').textContent;
		var time = xml.querySelector('timestamp').textContent;

		if (xml.querySelector('video isHD').textContent == '1') {
			meta.formats['HD'] = 'http://player.vimeo.com/play_redirect?clip_id=' + clipId + '&quality=hd&codecs=h264,vp6&type=html5_desktop_local&time=' + time + '&sig=' + sig;
		}
		meta.formats['SD'] = 'http://player.vimeo.com/play_redirect?clip_id=' + clipId + '&quality=sd&codecs=h264,vp6&type=html5_desktop_local&time=' + time + '&sig=' + sig;

		var defaultFormat = safari.extension.settings.vimeoFormat;
		if (meta.formats[defaultFormat]) {
			meta.useFormat = defaultFormat;
		} else {
			meta.useFormat = 'SD';
		}

		meta.poster = xml.querySelector('video thumbnail').textContent;
		meta.title = xml.querySelector('video caption').textContent;
		meta.author = xml.querySelector('video uploader_display_name').textContent;
		meta.authorLink = xml.querySelector('video uploader_url').textContent;
		meta.link = xml.querySelector('video url').textContent;
		meta.from = 'Vimeo';

		return meta;
	};

	self.startLoad = function(playerId, clipId, autoplay, event) {
		var req = new XMLHttpRequest();
		req.open('GET', 'http://player.vimeo.com/video/' + clipId, true);
		req.onreadystatechange = function(ev) {
			if (req.readyState === 4 && req.status === 200) {
				var meta = self.processMeta(clipId, req.responseXML);
				meta.autoplay = autoplay;
				injectVideo(event, playerId, meta);
			} else if (req.readyState === 4 && req.status === 404) {
				var meta = { error: '404 Error loading Vimeo video' };
				injectVideo(event, playerId, meta);
			}
		};
		req.send(null);
	};

	return self;
};

providers.push(newVimeo());