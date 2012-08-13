var newFacebook = function() {
	var self = newProvider();

	self.urlPatterns = [
		/^https?:\/\/([a-z\-\.]+)?static\.ak\.facebook\.com\/rsrc.php\/v1\/y2\/r\/5l8_EVv_jyW\.swf/i
	];

	self.enabled = function() {
		return safari.extension.settings.enableFacebook;
	};

	self.loadVideo = function(url, playerId, flashvars, event) {
		if (self.urlPatterns[0].test(url)) {
			var data = parseUrlEncoded(flashvars);
			var meta = self.processMeta(playerId, data, event);

			injectVideo(event, playerId, meta);
		}
	};

	self.processMeta = function(playerId, data, event) {
		var meta = {};

		meta.formats = {};
		if (data.highqual_src) {
			meta.formats['High'] = data.highqual_src;
			meta.formats['Low'] = data.lowqual_src;
		} else {
			meta.formats['Low'] = data.video_src;
		}

		var defaultFormat = safari.extension.settings.facebookFormat;
		if (meta.formats[defaultFormat]) {
			meta.useFormat = defaultFormat;
		} else {
			meta.useFormat = 'Low';
		}


		meta.poster = data.thumb_url;
		meta.title = data.video_title;
		meta.link = 'https://www.facebook.com/video/video.php?v=' + data.video_id;
		meta.author = data.video_owner_name;
		meta.authorLink = data.video_owner_href;
		meta.from = 'Facebook';
		meta.autoplay = false;

		return meta;
	};

	return self;
};

providers.push(newFacebook());