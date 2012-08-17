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

		if ((m = url.match(self.urlPatterns[1])) || (m = url.match(self.urlPatterns[3]))) {
			var clipId = m[1];
			self.startLoad(playerId, clipId, false, event);
			return true;
		}
		else if (self.urlPatterns[0].test(url) || self.urlPatterns[2].test(url)) {
			var data = parseUrlEncoded(flashvars);
			self.startLoad(playerId, data.clip_id, false, event);
			return true;
		}
		else {
			return false;
		}
	};

	self.processMeta = function(clipId, text) {
		var meta = {};

		var m = text.match(/clip[0-9_]+ = (\{[\s\S]*\});/i); // dotall doesn't exist in JS, so use [\s\S]
		var data = eval('(' + m[1] + ')'); // Vimeo doesn't use quotes always, so we can't use JSON.parse

		meta.formats = {};

		var sig = data.config.request.signature;
		var time = data.config.request.timestamp;

		data.config.video.files.h264.forEach(function(format) {
			meta.formats[format.toUpperCase()] = 'http://player.vimeo.com/play_redirect?quality=' + format + '&codecs=h264&clip_id=' + clipId + '&time=' + time + '&sig=' + sig + '&type=html5_desktop_local';
		});

		var defaultFormat = safari.extension.settings.vimeoFormat;
		if (meta.formats[defaultFormat]) {
			meta.useFormat = defaultFormat;
		} else {
			meta.useFormat = 'SD';
		}

		meta.poster = data.config.video.thumbnail;
		meta.title = data.config.video.title;
		meta.author = data.config.video.owner.name;
		meta.authorLink = data.config.video.owner.url;
		meta.link = data.config.video.url;
		meta.from = 'Vimeo';

		return meta;
	};

	self.startLoad = function(playerId, clipId, autoplay, event) {
		var req = new XMLHttpRequest();
		req.open('GET', 'http://player.vimeo.com/video/' + clipId, true);
		req.onreadystatechange = function(ev) {
			if (req.readyState === 4 && req.status === 200) {
				var meta = self.processMeta(clipId, req.responseText);
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