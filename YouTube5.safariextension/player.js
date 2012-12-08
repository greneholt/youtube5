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

var findPosition = function(el) {
	var left = top = 0;
	do {
		left += el.offsetLeft;
		top += el.offsetTop;
	} while (el = el.offsetParent);
	return [left, top];
};

var focusedPlayer;

var newPlayer = function(replace, width, height) {
	var self = {};

	self.width = width;
	self.height = height;

	self.floating = false;

	self.originalPlayer = replace;

	self.revert = function() {
		self.container.parentNode.replaceChild(self.originalPlayer, self.container);
	};

	self.container = document.createElement('div');
	self.container.className = 'youtube5container';
	self.container.style.width = self.width + 'px';
	self.container.style.height = self.height + 'px';

	self.player = create('div', self.container, 'youtube5player youtube5loading');
	self.player.style.width = self.width + 'px';
	self.player.style.height = self.height + 'px';
	self.player.style.position = 'relative';
	self.player.style.margin = '0 auto';

	self.topOverlay = create('div', self.player, 'youtube5top-overlay');
	self.bottomOverlay = create('div', self.player, 'youtube5bottom-overlay');

	self.info = create('div', self.player, 'youtube5info');

	self.useOriginal = create('div', self.info, 'youtube5use-original youtube5show-on-waiting');
	self.useOriginal.innerHTML = '&crarr; Use original player';
	self.useOriginal.addEventListener('click', self.revert, false);

	replace.parentNode.replaceChild(self.container, replace);

	self.updatePlayed = function() {
		var x = self.position.value / 1000 * (self.position.clientWidth - 10) + 10;
		self.played.style.width = x + 'px';
	};

	self.updatePlayerSize = function() {
		var width, height;

		if (self.floating) {
			width = self.video.videoWidth;
			height = self.video.videoHeight;

			var minWidth = window.innerWidth * 0.8;
			var minHeight = window.innerHeight * 0.8;

			if (width > window.innerWidth) {
				width = window.innerWidth;
			} else if (width < minWidth) {
				width = minWidth;
			}

			if (height > window.innerHeight) {
				height = window.innerHeight;
			} else if (height < minHeight) {
				height = minHeight;
			}
		} else {
			width = self.width;
			height = self.height;
		}

		var realAspectRatio = width/height;
		var nativeAspectRatio = self.video.videoWidth/self.video.videoHeight;

		// the player is wider than necessary, so fit by height
		if (realAspectRatio > nativeAspectRatio) {
			width = Math.round(height*nativeAspectRatio);
			height = height;
		} else { // taller than necessary
			width = width;
			height = Math.round(width/nativeAspectRatio);
		}
		self.player.style.width = width + 'px';
		self.player.style.height = height + 'px';

		return [width, height];
	};

	self.updateTime = function() {
		var remaining = self.video.duration - self.video.currentTime;

		self.timeElapsed.textContent = formatTime(self.video.currentTime);
		self.timeRemaining.textContent = '-' + formatTime(remaining);
	};

	self.updateLoaded = function() {
		if (isNaN(self.video.duration) || self.video.buffered.length == 0) return;

		var x = self.video.buffered.end(0) / self.video.duration * (self.position.clientWidth - 10) + 10;
		self.loaded.style.width = x + 'px';
	};

	self.updatePosition = function() {
		if (isNaN(self.video.duration)) return;

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
		if (isNaN(self.video.duration)) return;

		self.video.currentTime = self.position.value / 1000 * self.video.duration;
		self.updatePlayed();
		self.hideOverlay();
	};

	self.showOverlay = function() {
		self.player.className = self.player.className + ' youtube5overlayed';
	};

	self.hideOverlay = function() {
		self.player.className = self.player.className.replace(/\byoutube5overlayed\b/, '');
	};

	self.playOrPause = function() {
		if (self.video.paused) {
			if (self.player.className == 'youtube5player youtube5waiting') {
				self.player.className = 'youtube5player youtube5loading';
			}
			self.video.play();
			self.removePlayLarge();
			self.hideOverlay();
		} else {
			self.video.pause();
		}
		// set the focused player to this one
		focusedPlayer = self;
	};

	self.popInOrOut = function() {
		var transitionCss = 'width 0.5s ease-out, height 0.5s ease-out, left 0.5s ease-out, top 0.5s ease-out'

		if (self.floating) {
			self.floating = false;

			var position = findPosition(self.player);

			// setup the starting point of the animation

			self.player.style.left = position[0] + 'px';
			self.player.style.top = position[1] + 'px';
			self.player.style.margin = '0 auto';

			self.player.offsetWidth; // Force reflow hack. Makes the animation use the proper start positions.

			// enable the transition animation before making changes
			self.player.style.webkitTransition = transitionCss;

			self.updatePlayerSize();
			self.player.style.left = self.originalPosition[0] + 'px';
			self.player.style.top = self.originalPosition[1] + 'px';

			self.player.addEventListener('webkitTransitionEnd', self.dockedTransitionComplete, false);
		} else {
			self.floating = true;

			self.originalPosition = findPosition(self.player);

			// when we change its dom position, the video stops playing
			var paused = self.video.paused;
			document.body.appendChild(self.player);
			if (!paused) {
				self.video.play();
			}

			// setup the starting point of the animation
			self.player.style.position = 'absolute';
			self.player.style.left = self.originalPosition[0] + 'px';
			self.player.style.top = self.originalPosition[1] + 'px';
			self.player.style.zIndex = 100000;
			self.player.style.webkitBoxShadow = '0 0 20px #000';

			self.player.offsetWidth; // Force reflow hack. Makes the animation use the proper start positions.

			// enable the transition animation before making changes
			self.player.style.webkitTransition = transitionCss;

			var size = self.updatePlayerSize();
			newWidth = size[0];
			newHeight = size[1];

			self.player.style.left = document.body.scrollLeft + (window.innerWidth - newWidth) / 2 + 'px';
			self.player.style.top = document.body.scrollTop +  (window.innerHeight - newHeight) / 2 + 'px';

			self.player.addEventListener('webkitTransitionEnd', self.floatingTransitionComplete, false);
		}
	};

	self.floatingTransitionComplete = function(event) {
		if (event.propertyName != 'left') return; // don't allow the animation to be short circuited by other transitions completing

		self.player.style.webkitTransition = null;

		self.player.style.left = '50%';
		self.player.style.margin = '0 0 0 ' + -self.player.clientWidth/2 + 'px';

		self.player.removeEventListener('webkitTransitionEnd', self.floatingTransitionComplete, false);

		self.updatePosition();
		self.updateLoaded();
	};

	self.dockedTransitionComplete = function(event) {
		if (event.propertyName != 'left') return; // don't allow the animation to be short circuited by other transitions completing

		self.player.style.webkitTransition = null;

		var paused = self.video.paused;
		self.container.appendChild(self.player);
		if (!paused) {
			self.video.play();
		}

		// reset all the styles we changed
		self.player.style.position = 'relative';
		self.player.style.left = null;
		self.player.style.top = null;
		self.player.style.zIndex = null;
		self.player.style.webkitBoxShadow = null;

		self.player.removeEventListener('webkitTransitionEnd', self.dockedTransitionComplete, false);

		self.updatePosition();
		self.updateLoaded();
	}

	self.removePlayLarge = function() {
		if(self.playLarge) {
			self.player.style.background = null;
			self.player.style.backgroundSize = null;
			self.player.removeChild(self.playLarge);
			self.playLarge = null;
		}
	}

	self.setVolume = function(volume) {
		self.video.muted = volume < 0.02;
		self.video.volume = volume;
		self.updateVolumeIndicator();

		if (self.meta.volumeCallback) {
			self.meta.volumeCallback(volume);
		}
	};

	self.changeQuality = function(event) {
		event.preventDefault();

		var format = event.target.textContent;
		var paused = self.video.paused;
		self.video.src = self.meta.formats[format];
		self.video.preload = 'auto';
		if (!paused) {
			self.video.play();
		}

		var nodes = event.target.parentNode.parentNode.childNodes;
		for (i = 0; i < nodes.length; i++) {
			nodes[i].className = '';
		}

		event.target.parentNode.className = 'youtube5current-format';
	};

	self.initVideo = function() {
		self.updatePlayerSize();
		self.createControls();
		self.updateTime();
		self.setVolume(self.meta.volume);

		self.video.removeEventListener('loadedmetadata', self.initVideo, false);
		self.video.addEventListener('loadedmetadata', function() {
			self.seek();
			self.updateTime();
		}, false);
	};

	self.injectVideo = function(meta) {
		// don't allow injecting the video twice
		if (self.meta) return;

		self.meta = meta;

		if (self.meta.error) {
			self.player.className = 'youtube5player error';
			self.error = create('div', self.player, 'youtube5error');
			self.error.innerHTML = self.meta.error;
			return;
		}

		self.video = document.createElement('video');
		self.video = create('video', self.player);
		self.video.src = meta.formats[meta.useFormat];

		self.player.insertBefore(self.video, self.topOverlay);

		if (self.meta.autoplay) {
			self.video.play();
		} else {
			self.player.className = 'youtube5player youtube5waiting';
			self.player.style.background = '#000 url(' + meta.poster + ') no-repeat center center';
			self.player.style.backgroundSize = '100% auto';
			self.video.preload = 'none';
		}

		if (self.meta.title) {
			var title = create('div', self.info, 'youtube5title youtube5show-on-waiting');
			var link = create('a', title);
			link.textContent = self.meta.title;
			link.href = self.meta.link;
		}

		if (self.meta.author) {
			var author = create('div', self.info, 'youtube5author youtube5show-on-waiting');
			author.textContent = 'By ';
			var link = create('a', author);
			link.textContent = self.meta.author;
			link.href = self.meta.authorLink;
		}

		self.formats = create('div', self.info, 'youtube5formats');
		self.from = create('div', self.formats, 'youtube5from');
		self.from.textContent = self.meta.from;

		self.formatList = create('ul', self.formats);
		for (name in self.meta.formats) {
			var format = create('li', self.formatList);
			var link = create('a', format);
			link.textContent = name;
			link.href = self.meta.formats[name];
			link.addEventListener('click', self.changeQuality, false);

			if (meta.useFormat == name) {
				format.className = 'youtube5current-format';
			}
		}

		self.replay = create('div', self.info, 'youtube5replay');
		self.replay.innerHTML = '&larr; Replay';
		self.closeOverlay = create('div', self.info, 'youtube5close-overlay');
		self.closeOverlay.textContent = 'X';

		self.infoButton = create('div', self.player, 'youtube5info-button');
		self.infoButton.textContent = 'i';

		if (!self.meta.autoplay) {
			self.playLarge = create('div', self.player, 'youtube5play-large');

			self.playLarge.addEventListener('click', function() {
				self.playOrPause();
			}, false);
		}

		self.video.addEventListener('loadedmetadata', self.initVideo, false);

		self.infoButton.addEventListener('click', self.showOverlay, false);

		self.info.addEventListener('click', function(event) {
			if (event.target == self.info) {
				self.playOrPause();
			}
		}, false);

		self.replay.addEventListener('click', function() {
			self.video.play();
			self.player.className = 'youtube5player';
		}, false);

		self.closeOverlay.addEventListener('click', self.hideOverlay, false);

		self.video.addEventListener('ended', function() {
			self.video.pause();
			self.player.className = 'youtube5player youtube5overlayed youtube5replay';
		}, false);
	};

	self.createControls = function() {
		self.player.className = 'youtube5player';

		self.controls = create('div', self.player, 'youtube5controls');

		// if the video is already playing, we need to set the right classname
		if (!self.video.paused) {
			self.controls.className = 'youtube5controls youtube5play';
		}

		self.playPause = create('div', self.controls, 'youtube5play-pause');
		self.timeElapsed = create('div', self.controls, 'youtube5time-elapsed');
		self.fullscreen = create('div', self.controls, 'youtube5fullscreen');
		self.popOut = create('div', self.controls, 'youtube5pop-out');
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

		self.playPause.addEventListener('click', self.playOrPause, false);

		self.popOut.addEventListener('click', self.popInOrOut, false);

		self.fullscreen.addEventListener('click', function() {
			self.video.webkitEnterFullScreen();
		}, false);

		self.volumeSlider.addEventListener('change', function() {
			self.setVolume(self.volumeSlider.value / 100);
		}, false);

		self.volumeMax.addEventListener('click', function() {
			self.setVolume(1);
			self.updateVolumeSlider();
		}, false);

		self.volumeMute.addEventListener('click', function() {
			self.setVolume(0);
			self.updateVolumeSlider();
		}, false);

		self.position.addEventListener('change', self.seek, false);

		self.video.addEventListener('progress', self.updateLoaded, false);

		self.video.addEventListener('timeupdate', self.updatePosition, false);

		self.video.addEventListener('volumechange', self.updateVolumeSlider, false);

		self.video.addEventListener('play', function() {
			self.controls.className = 'youtube5controls youtube5play';
		}, false);

		self.video.addEventListener('pause', function() {
			self.controls.className = 'youtube5controls youtube5pause';
		}, false);

		// keyboard shortcuts
		document.addEventListener('keypress', function(event) {
			if (event.target == document.body && focusedPlayer == self) {
				if (event.keyCode == 32) { // space
					event.preventDefault();
					self.playOrPause();
				}
			}
		}, false);

		document.addEventListener('keydown', function(event) {
			if (event.target == document.body && focusedPlayer == self) {
				if (event.keyCode == 37) { // left arrow
					event.preventDefault();
					if (self.video.currentTime > 5) {
						self.video.currentTime -= 5;
					} else {
						self.video.currentTime = 0;
					}
					self.updatePosition();
				} else if (event.keyCode == 39) { // right arrow
					event.preventDefault();
					if (self.video.currentTime < self.video.duration - 5) {
						self.video.currentTime += 5;
					} else {
						self.video.currentTime = self.video.duration;
					}
					self.updatePosition();
				}
			}
		}, false);
	};

	return self;
};
