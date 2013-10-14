var parseUrlEncoded = function(text) {
	var data = {};

	if (text) {
		var pairs = text.split('&');
		pairs.forEach(function(pair) {
			pair = pair.split('=');
			data[pair[0]] = decodeURIComponent(pair[1]).replace(/\+/g, ' ');
		});
	}

	return data;
};

var parseTimeCode = function(text) {
	var seconds = 0;

	var match = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$/.exec(text);
	if (match) {
		[3600, 60, 1].forEach(function(multiplier, i) {
			var timeValue = parseInt(match[i + 1]);
			if (timeValue) {
				seconds += multiplier * timeValue;
			}
		});
	}

	return seconds;
};

var getStartTime = function(params) {
	if (params.t) {
		return parseTimeCode(params.t);
	} else if (params.time) {
		return parseTimeCode(params.time);
	} else if (params.start) {
		return parseTimeCode(params.start);
	} else {
		return null;
	}
};

var somePattern = function(message, patterns) {
	return patterns.some(function (pattern) {
		return pattern.test(message);
	});
};

var getDomain = function(url) {
	var match = url.match(/https?:\/\/(?:www.)?([a-z0-9\-.]+)/i);
	if (match) {
		return match[1];
	}
	else {
		return '';
	}
};