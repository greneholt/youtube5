var create = function(name, parent, className) {
	var elem = document.createElement(name);
	if (className) {
		elem.className = className;
	}
	parent.appendChild(elem);
	return elem;
};

var formatTime = function(seconds) {
	var m = Math.floor(seconds / 60);
	var s = Math.floor(seconds % 60);
	
	if (m < 10) {
		m = '0' + m;
	}
	
	if (s < 10) {
		s = '0' + s;
	}
	
	return m + ':' + s;
};

var newPlayer = function(replace, width, height) {
	var self = {};
	
	self.width = width;
	self.height = height;
	
	self.frame = document.createElement('iframe');
	self.frame.frameBorder = 0;
	self.frame.width = self.width;
	self.frame.height = self.height;
	self.frame.addEventListener('load', function() {
		var stylesheet = create('link', self.frame.contentDocument.head);
		stylesheet.type = 'text/css';
		stylesheet.rel = 'stylesheet';
		stylesheet.href = safari.extension.baseURI + 'player.css';
	
		self.player = create('div', self.frame.contentDocument.body, 'youtube5player');
		self.player.style.width = self.width + 'px';
		self.player.style.height = self.height + 'px';
	}, true);
	
	replace.parentNode.replaceChild(self.frame, replace);
	
	self.updatePlayed = function() {
		var x = self.position.value / 1000 * (self.position.clientWidth - 10) + 10;
		self.played.style.width = x + 'px';
	};
	
	self.updateSize = function() {
		var realAspectRatio = self.width/self.height;
		var nativeAspectRatio = self.video.videoWidth/self.video.videoHeight;
		
		var width, height;
		
		// the player is wider than necessary, so fit by height
		if (realAspectRatio > nativeAspectRatio) {
			width = Math.round(self.height*nativeAspectRatio);
			height = self.height;
		} else { // taller than necessary
			width = self.width;
			height = Math.round(self.width/nativeAspectRatio);
		}
		self.video.width = width;
		self.video.height = height;
		self.player.style.width = width + 'px';
		self.player.style.height = height + 'px';
	};
	
	self.updateTime = function() {
		var remaining = self.video.duration - self.video.currentTime;
		
		self.timeElapsed.textContent = formatTime(self.video.currentTime);
		self.timeRemaining.textContent = '-' + formatTime(remaining);
	};
	
	self.updateLoaded = function() {
		var x = self.video.buffered.end(0) / self.video.duration * (self.position.clientWidth - 10) + 10;
		self.loaded.style.width = x + 'px';
	};
	
	self.updatePosition = function() {
		self.position.value = self.video.currentTime / self.video.duration * 1000;
		self.updatePlayed();
		self.updateTime();
	};
	
	self.updateVolumeSlider = function() {
		self.volumeSlider.value = self.video.volume * 100;
		self.updateVolumeIndicator();
	};
	
	self.updateVolumeIndicator = function() {
		if (self.video.volume > 0.75) {
			self.volume.className = 'youtube5volume youtube5high';
		} else if (self.video.volume > 0.3) {
			self.volume.className = 'youtube5volume youtube5med';
		} else if (self.video.volume > 0.02) {
			self.volume.className = 'youtube5volume youtube5low';
		} else {
			self.volume.className = 'youtube5volume youtube5off';
		}
	};
	
	self.seek = function() {
		self.video.currentTime = self.position.value / 1000 * self.video.duration;
		self.updatePlayed();
	};
	
	self.showOverlay = function() {
		self.player.className = 'youtube5player youtube5overlayed';
	};
	
	self.hideOverlay = function() {
		self.player.className = 'youtube5player';
	};
	
	self.playOrPause = function() {
		if (self.video.paused) {
			self.video.play();
		} else {
			self.video.pause();
		}
	};
	
	self.setVolume = function(volume) {
		self.video.muted = volume < 0.02;
		self.video.volume = volume;
		self.updateVolumeIndicator();
	};
	
	self.changeQuality = function(event) {
		event.preventDefault();
		
		var format = event.target.textContent;
		self.video.autoplay = true;
		self.video.src = self.meta.formats[format];
		
		var nodes = event.target.parentNode.parentNode.childNodes;
		for (i = 0; i < nodes.length; i++) {
			nodes[i].className = '';
		}
		
		event.target.parentNode.className = 'youtube5current-format';
	};
	
	self.initVideo = function() {
		self.updateSize();
		self.createControls();
		self.updateTime();
		
		self.video.removeEventListener('loadedmetadata', self.initVideo, true);
		self.video.addEventListener('loadedmetadata', function() {
			self.updateSize();
			self.seek();
			self.updateTime();
		}, true);
	};
	
	self.injectVideo = function(meta) {
		// don't allow injecting the video twice
		if (self.meta) return;
		
		self.meta = meta;
		
		self.video = create('video', self.player);
		self.video.src = meta.formats[meta.useFormat];
		self.video.width = self.width;
		self.video.height = self.height;
		
		if (self.meta.autoplay) {
			self.video.autoplay = true;
		} else {
			self.player.style.background = '#000 url(' + meta.poster + ') no-repeat center center';
			self.player.style.backgroundSize = '100% auto';
			self.video.preload = 'none';
		}
		
		self.overlay = create('div', self.player, 'youtube5overlay');
		
		if (self.meta.title) {
			var title = create('div', self.overlay, 'youtube5title');
			var link = create('a', title);
			link.textContent = self.meta.title;
			link.href = self.meta.link;
			link.target = '_parent';
		}
		
		if (self.meta.author) {
			var author = create('div', self.overlay, 'youtube5author');
			author.textContent = 'By ';
			var link = create('a', author);
			link.textContent = self.meta.author;
			link.href = self.meta.authorLink;
			link.target = '_parent';
		}
		
		self.formats = create('div', self.overlay, 'youtube5formats');
		self.from = create('div', self.formats, 'youtube5from');
		self.from.textContent = self.meta.from;
		
		self.formatList = create('ul', self.formats);
		for (name in self.meta.formats) {
			var format = create('li', self.formatList);
			var link = create('a', format);
			link.textContent = name;
			link.href = self.meta.formats[name];
			link.target = '_parent';
			link.addEventListener('click', self.changeQuality, true);
			
			if (meta.useFormat == name) {
				format.className = 'youtube5current-format';
			}
		}
		self.replay = create('div', self.overlay, 'youtube5replay');
		self.replay.innerHTML = '&larr; Replay';
		self.closeOverlay = create('div', self.overlay, 'youtube5close-overlay');
		self.closeOverlay.textContent = 'X';
		
		self.info = create('div', self.player, 'youtube5info');
		self.info.textContent = 'i';
		
		if (!self.meta.autoplay) {
			self.playLarge = create('div', self.player, 'youtube5play-large');

			self.playLarge.addEventListener('click', function() {
				self.player.style.background = null;
				self.player.style.backgroundSize = null;
				self.video.play();
				self.player.removeChild(self.playLarge);
			}, true);
		}
		
		self.video.addEventListener('loadedmetadata', self.initVideo, true);
		
		self.info.addEventListener('click', self.showOverlay, true);
		
		self.replay.addEventListener('click', function() {
			self.video.play();
			self.player.className = 'youtube5player';
		}, true);
		
		self.closeOverlay.addEventListener('click', self.hideOverlay, true);
		
		self.video.addEventListener('ended', function() {
			self.video.pause();
			self.player.className = 'youtube5player youtube5overlayed youtube5replay';
		}, true);
	};
	
	self.createControls = function() {
		self.controls = create('div', self.player, 'youtube5controls');
		
		// if the video is already playing, we need to set the right classname
		if (!self.video.paused) {
			self.controls.className = 'youtube5controls youtube5play';
		}
		
		self.playPause = create('div', self.controls, 'youtube5play-pause');
		self.timeElapsed = create('div', self.controls, 'youtube5time-elapsed');
		self.fullscreen = create('div', self.controls, 'youtube5fullscreen');
		self.volume = create('div', self.controls, 'youtube5volume');
		create('div', self.volume, 'youtube5volume-indicator');
		self.volumePopup = create('div', self.volume, 'youtube5volume-popup');
		self.volumeMax = create('div', self.volumePopup, 'youtube5volume-max');

		self.volumeSlider = create('input', self.volumePopup, 'youtube5volume-slider');
		self.volumeSlider.type = 'range';
		self.volumeSlider.min = 0;
		self.volumeSlider.max = 100;
		self.volumeSlider.value = 100;

		self.volumeMute = create('div', self.volumePopup, 'youtube5volume-mute');
		self.timeRemaining = create('div', self.controls, 'youtube5time-remaining');
		self.progress = create('div', self.controls, 'youtube5progress');
		self.loaded = create('div', self.progress, 'youtube5loaded');
		self.played = create('div', self.progress, 'youtube5played');

		self.position = create('input', self.progress, 'youtube5position');
		self.position.type = 'range';
		self.position.min = 0;
		self.position.max = 1000;
		self.position.value = 0;
		
		self.playPause.addEventListener('click', self.playOrPause, true);
		
		self.fullscreen.addEventListener('click', function() {
			self.video.webkitEnterFullScreen();
		}, true);

		self.volumeSlider.addEventListener('change', function() {
			self.setVolume(self.volumeSlider.value / 100);
		}, true);

		self.volumeMax.addEventListener('click', function() {
			self.setVolume(1);
			self.updateVolumeSlider();
		}, true);

		self.volumeMute.addEventListener('click', function() {
			self.setVolume(0);
			self.updateVolumeSlider();
		}, true);
		
		self.position.addEventListener('change', self.seek, true);
		
		self.video.addEventListener('progress', self.updateLoaded, true);
		
		self.video.addEventListener('timeupdate', self.updatePosition, true);
		
		self.video.addEventListener('volumechange', self.updateVolumeSlider, true);
		
		self.video.addEventListener('play', function() {
			self.controls.className = 'youtube5controls youtube5play';
		}, true);

		self.video.addEventListener('pause', function() {
			self.controls.className = 'youtube5controls youtube5pause';
		}, true);
	};
	
	return self;
};
