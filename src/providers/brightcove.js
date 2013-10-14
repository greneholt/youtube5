var newBrightcove = function() {
	var self = newProvider();

	self.videoUrlPatterns = [
		/brightcove\.com\/services\/viewer\//i
	];

	self.enabled = function() {
		return safari.extension.settings.enableBrightcove;
	};

	self.loadVideo = function(url, playerId, flashvars, event) {
		url = event.message.url;

		if (self.videoUrlPatterns[0].test(url)) {
			self.startLoad(playerId, url.replace(/\/viewer\/\w+(?:\.swf)?\?/i, '/viewer/htmlFederated?'), event);
			return true;
		}
		else {
			return false;
		}
	};

	self.processMeta = function(text) {
		var meta = {};

		var m = text.match(/experienceJSON = (\{.*\});/i);
		var data = JSON.parse(m[1]);

		meta.formats = {};

		if (!data.data.programmedContent.videoPlayer || ! data.data.programmedContent.videoPlayer.mediaDTO) {
			meta = {error: 'Not a Brightcove video'};
			return meta;
		}

		var video = data.data.programmedContent.videoPlayer.mediaDTO;

		meta.poster = video.videoStillURL;
		meta.title = video.displayName;
		meta.author = video.publisherName;
		meta.from = 'Brightcove';

		var lastFormat;
		video.renditions.forEach(function(format) {
			meta.formats[format.frameHeight + 'p'] = format.defaultURL;
			lastFormat = format.frameHeight + 'p';
		});

		meta.useFormat = lastFormat;

		return meta;
	};

	self.startLoad = function(playerId, url, event) {
		var req = new XMLHttpRequest();
		req.open('GET', url, true);
		req.onreadystatechange = function(ev) {
			if (req.readyState === 4 && req.status === 200) {
				var meta = self.processMeta(req.responseText);
				injectVideo(event, playerId, meta);
			} else if (req.readyState === 4 && req.status === 404) {
				var meta = { error: '404 Error loading Brightcove video' };
				injectVideo(event, playerId, meta);
			}
		};
		req.send(null);
	};

	return self;
};

providers.push(newBrightcove());