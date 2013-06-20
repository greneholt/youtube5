var newFacebook = function() {
	var self = newProvider();

	self.urlPatterns = [
		/\/rsrc.php\/.*\.swf/i
	];

	self.canLoad = function(message) {
		return self.urlPatterns.some(function(pattern) {
			return pattern.test(message.url) && message.flashvars.indexOf('thumbnail_src') !== -1;
		});
	};

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

		var params = JSON.parse(data.params);
		var video_data = params.video_data[0];

		meta.formats = {};
		if (video_data.hd_src) {
			meta.formats['HD'] = video_data.hd_src;
		}
		meta.formats['SD'] = video_data.sd_src;

		var defaultFormat = safari.extension.settings.facebookFormat;
		if (meta.formats[defaultFormat]) {
			meta.useFormat = defaultFormat;
		} else {
			meta.useFormat = 'SD';
		}

		meta.title = 'Facebook video';
		meta.poster = video_data.thumbnail_src;;
		meta.link = params.permalink_url;
		meta.from = 'Facebook';
		meta.autoplay = params.autoplay;

		return meta;
	};

	return self;
};

providers.push(newFacebook());