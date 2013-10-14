/*
YouTube5 Copyright 2010 Connor McKay

YouTube5 is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

YouTube5 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
*/

var injectVideo = function(event, playerId, meta) {
	meta.volume = safari.extension.settings.volume;
	event.target.page.dispatchMessage("injectVideo", { playerId: playerId, meta: meta });
};

var providers = [];

var newProvider = function() {
	var self = {};

	self.videoUrlPatterns = [];
	self.blockScriptUrlPatterns = [];

	self.enabled = function() {
		return false;
	};

	self.canLoadVideo = function(message) {
		return somePattern(message.url, self.videoUrlPatterns);
	};

	self.shouldBlockScript = function(message) {
		return somePattern(message.url, self.blockScriptUrlPatterns);
	};

	self.loadVideo = function(url, playerId, flashvars, event) {
		return false;
	};

	return self;
};

var canLoad = function(event) {
	var message = event.message;

	for (var i = 0; i < providers.length; i++) {
		if (!providers[i].enabled())
			continue;

		if (message.type == 'script' && providers[i].shouldBlockScript(message)) {
			event.message = 'block';
			return;
		}
		else if ((message.type == 'plugin' || message.type == 'iframe') && providers[i].canLoadVideo(message)) {
			event.message = 'video';
			return;
		}
	}

	event.message = 'allow';
};

var loadVideo = function(event) {
	var url = event.message.url;
	var playerId = event.message.playerId;
	var flashvars = event.message.flashvars;

	var loaded = providers.some(function(provider) {
		return provider.enabled() && provider.loadVideo(url, playerId, flashvars, event);
	});

	if (!loaded) {
		var meta = { error: 'Unknown video URL<br />' + url };
		injectVideo(event, playerId, meta);
	}
};

var updateVolume = function(event) {
	safari.extension.settings.volume = event.message;
};

safari.application.addEventListener('message', function(event) {
	if (event.name == 'canLoad') {
		canLoad(event);
	} else if (event.name == 'loadVideo') {
		loadVideo(event);
	} else if (event.name == 'updateVolume') {
		updateVolume(event);
	}
}, true);