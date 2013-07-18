var players = {};

var getFlashvars = function(el) {
	var flashvars = el.getAttribute('flashvars');
	if (!flashvars) {
		if (flashvars = el.querySelector('param[name=flashvars]')) {
			flashvars = flashvars.getAttribute('value');
		}
	}
	return flashvars;
}

document.addEventListener('beforeload', function(event) {
	if (event.target.youtube5allowedToLoad) return;

	var message = {};

	if (event.target instanceof HTMLObjectElement || event.target instanceof HTMLEmbedElement) {
		message.type = 'plugin';
	}
	else if (event.target instanceof HTMLIFrameElement) {
		message.type = 'iframe';
	}
	else {
		event.target.youtube5allowedToLoad = true;
		return;
	}

	/*
	Some websites can have flash checking disabled by adding the following to the getRequestParameter function of swfobject.

	if(c=='detectflash')return'false';
	*/

	message.location = window.location.href;
	message.url = event.url;
	message.flashvars = getFlashvars(event.target);

	// for some reason the url doesn't stay in the event when its passed to the global page, so we have to set it as the message
	var result = safari.self.tab.canLoad(event, message);

	if (result == 'video') {
		// sometimes both <embed> and <object> will trigger a beforeload event, even after one of the two has been removed
		if (!event.target.parentNode) return;

		event.preventDefault();

		var playerId = Math.round(Math.random()*1000000000);

		// sometimes the scroll dimmensions of the video are zero, so fall back to the designated width and height
		var width = event.target.scrollWidth;
		var height = event.target.scrollHeight;

		if (width == 0 || height == 0) {
			width = event.target.width;
			height = event.target.height;
		}

		event.target.youtube5allowedToLoad = true;

		var flashvars = getFlashvars(event.target);

		var replace = event.target;

		// little hack to get around YouTube's flash detection. This moves the YouTube5 player one node up the dom tree, breaking their code and preventing it from being removed.
		if (replace.parentNode.id === 'player-api') {
			replace = replace.parentNode;
		}

		players[playerId] = newPlayer(replace, width, height);
		safari.self.tab.dispatchMessage("loadVideo", { url: event.url, playerId: playerId, flashvars: flashvars });
	}
	else if (result == 'block') {
		event.preventDefault();
	}
}, true);

var updateVolume = function(volume) {
	safari.self.tab.dispatchMessage("updateVolume", volume);
};

var injectVideo = function(event) {
	var playerId = event.message.playerId;
	var meta = event.message.meta;
	meta.volumeCallback = updateVolume;

	// these messages are sent to iframes as well, so check if the requested video actually belongs to this frame
	if (players[playerId]) {
		players[playerId].injectVideo(meta);
	}
};

safari.self.addEventListener("message", function(event) {
	if (event.name === "injectVideo") {
		injectVideo(event);
	}
}, true);