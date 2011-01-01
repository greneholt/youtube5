if (!/youtube\.com\/leanback/.test(document.location.href)) {
	var players = {};

	document.addEventListener('beforeload', function(event) {
		if (event.target.youtube5checked) return;
		
		event.target.youtube5checked = true;
		
		// for some reason the url doesn't stay in the event when its passed to the global page, so we have to set it as the message
		var result = safari.self.tab.canLoad(event, event.url);
		
		if (result === 'video') {
			// sometimes both <embed> and <object> will trigger a beforeload event, even after one of the two has been removed
			if (!event.target.parentNode) return;
			
			event.preventDefault();
			
			var playerId = Math.round(Math.random()*1000000000);
			
			players[playerId] = newPlayer(event.target, event.target.scrollWidth, event.target.scrollHeight);
			var flashvars = event.target.getAttribute('flashvars');
			if (!flashvars) {
				if (flashvars = event.target.querySelector('param[name=flashvars]')) {
					flashvars = flashvars.getAttribute('value');
				}
			}
			safari.self.tab.dispatchMessage("loadVideo", { url: event.url, playerId: playerId, flashvars: flashvars });
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
}