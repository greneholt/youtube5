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
	var left, top;
	left = top = 0;
	do {
		left += el.offsetLeft;
		top += el.offsetTop;
	} while (el = el.offsetParent);
	return [left, top];
};

var addClass = function(el, className) {
	el.className += ' ' + className;
};

var removeClass = function(el, className) {
	el.className = el.className.replace(new RegExp('\\b' + className + '\\b'), '');
};

var hasClass = function(el, className) {
	return el.className.indexOf(className) !== -1;
}

var focusedPlayer;

var newPlayer = function(replace, width, height) {
	var self = {};

	self.width = width;
	self.height = height;

	self.floating = false;
	self.hovered = false;

	self.originalPlayer = replace;

	self.hoverTimeoutId = null;

	self.revert = function() {
		self.placeholder.parentNode.replaceChild(self.originalPlayer, self.placeholder);
	};

	self.placeholder = document.createElement('div');
	self.placeholder.className = 'youtube5placeholder';
	self.placeholder.style.width = self.width + 'px';
	self.placeholder.style.height = self.height + 'px';

	self.container = create('div', self.placeholder, 'youtube5container');
	self.container.style.width = self.width + 'px';
	self.container.style.height = self.height + 'px';
	self.container.style.position = 'relative';
	self.container.style.margin = '0 auto';

	self.player = create('div', self.container, 'youtube5player youtube5loading');
	self.player.style.width = '100%';
	self.player.style.height = '100%';

	self.topOverlay = create('div', self.player, 'youtube5top-overlay');
	self.bottomOverlay = create('div', self.player, 'youtube5bottom-overlay');

	self.info = create('div', self.player, 'youtube5info');

	self.useOriginal = create('div', self.info, 'youtube5use-original youtube5show-on-waiting');
	self.useOriginal.innerHTML = '&crarr; Use original player';
	self.useOriginal.addEventListener('click', self.revert, false);

	var originalParent = replace.parentNode;
	if (originalParent && !originalParent.getAttribute("data-youtube5-cloned")) {
		var clonedParent = originalParent.cloneNode(true);
		originalParent.id = "youtube5-replace-parentNode";

		clonedParent.setAttribute("data-youtube5-cloned", true);
		clonedParent.style.display = "none";

		// Insert clonedParent after originalParent
		originalParent.parentNode.insertBefore(clonedParent, originalParent.nextSibling);

		originalParent.replaceChild(self.placeholder, replace);
	}

	self.updateHoverTimeout = function() {
		if (!self.hovered) {
			self.hovered = true;
			addClass(self.player, 'youtube5hover');
		} else if (self.hoverTimeoutId !== null) {
			window.clearTimeout(self.hoverTimeoutId);
		}
		self.hoverTimeoutId = window.setTimeout(self.unHover, 2000);
	};

	self.player.addEventListener('mousemove', self.updateHoverTimeout, false);

	self.unHover = function() {
		self.hovered = false;
		// we need to temporarily disable the mousemove event listener because
		// for some reason safari fires a mousemove event when the cursor is changed.
		// https://bugs.webkit.org/show_bug.cgi?id=85343
		self.player.removeEventListener('mousemove', self.updateHoverTimeout, false);
		window.setTimeout(self.unHoverTransitionComplete, 500);
		removeClass(self.player, 'youtube5hover');
		self.hoverTimeoutId = null;
	};

	self.unHoverTransitionComplete = function() {
		self.player.addEventListener('mousemove', self.updateHoverTimeout, false);
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
		self.container.style.width = width + 'px';
		self.container.style.height = height + 'px';

		return [width, height];
	};

	self.updateTime = function() {
		var remaining = self.video.duration - self.video.currentTime;

		self.timeElapsed.textContent = formatTime(self.video.currentTime);
		self.timeRemaining.textContent = '-' + formatTime(remaining);
	};

	self.updatePlayed = function() {
		self.played.style.width = self.position.value / 10 + '%';
	};

	self.updateLoaded = function() {
		if (isNaN(self.video.duration) || self.video.buffered.length == 0) return;

		self.loaded.style.width = self.video.buffered.end(0) / self.video.duration * 100 + '%';
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
		addClass(self.player, 'youtube5overlayed');
	};

	self.hideOverlay = function() {
		removeClass(self.player, 'youtube5overlayed');
	};

	self.playOrPause = function() {
		if (self.video.paused) {
			if (hasClass(self.player, 'youtube5waiting')) {
				removeClass(self.player, 'youtube5waiting');
				addClass(self.player, 'youtube5loading');
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
		if (document.webkitIsFullScreen) return;

		var transitionCss = 'width 0.5s ease-out, height 0.5s ease-out, left 0.5s ease-out, top 0.5s ease-out';

		if (self.floating) {
			self.floating = false;

			var position = findPosition(self.container);

			// setup the starting point of the animation

			self.container.style.left = position[0] + 'px';
			self.container.style.top = position[1] + 'px';
			self.container.style.margin = '0 auto';

			self.container.offsetWidth; // Force reflow hack. Makes the animation use the proper start positions.

			// enable the transition animation before making changes
			self.container.style.webkitTransition = transitionCss;

			self.updatePlayerSize();
			self.container.style.left = self.originalPosition[0] + 'px';
			self.container.style.top = self.originalPosition[1] + 'px';

			self.container.addEventListener('webkitTransitionEnd', self.dockedTransitionComplete, false);
		} else {
			self.floating = true;

			self.originalPosition = findPosition(self.container);

			// when we change its dom position, the video stops playing
			var paused = self.video.paused;
			document.body.appendChild(self.container);
			if (!paused) {
				self.video.play();
			}

			// setup the starting point of the animation
			self.container.style.position = 'absolute';
			self.container.style.left = self.originalPosition[0] + 'px';
			self.container.style.top = self.originalPosition[1] + 'px';
			self.container.style.zIndex = 100000;
			self.container.style.webkitBoxShadow = '0 0 20px #000';

			var ignore = self.container.offsetWidth; // Force reflow hack. Makes the animation use the proper start positions.

			// enable the transition animation before making changes
			self.container.style.webkitTransition = transitionCss;

			var size = self.updatePlayerSize();
			var newWidth = size[0];
			var newHeight = size[1];

			self.container.style.left = document.body.scrollLeft + (window.innerWidth - newWidth) / 2 + 'px';
			self.container.style.top = document.body.scrollTop +  (window.innerHeight - newHeight) / 2 + 'px';

			self.container.addEventListener('webkitTransitionEnd', self.floatingTransitionComplete, false);
		}
	};

	self.toggleFullScreen = function() {
		if (document.webkitIsFullScreen) {
			document.webkitCancelFullScreen();
		} else {
			self.player.webkitRequestFullScreen();
		}
	};

	self.floatingTransitionComplete = function(event) {
		if (event.propertyName != 'left') return; // don't allow the animation to be short circuited by other transitions completing

		self.container.style.webkitTransition = null;

		self.container.style.left = '50%';
		self.container.style.margin = '0 0 0 ' + -self.container.clientWidth/2 + 'px';

		self.container.removeEventListener('webkitTransitionEnd', self.floatingTransitionComplete, false);
	};

	self.dockedTransitionComplete = function(event) {
		if (event.propertyName != 'left') return; // don't allow the animation to be short circuited by other transitions completing

		self.container.style.webkitTransition = null;

		var paused = self.video.paused;
		self.placeholder.appendChild(self.container);
		if (!paused) {
			self.video.play();
		}

		// reset all the styles we changed
		self.container.style.position = 'relative';
		self.container.style.left = null;
		self.container.style.top = null;
		self.container.style.zIndex = null;
		self.container.style.webkitBoxShadow = null;

		self.container.removeEventListener('webkitTransitionEnd', self.dockedTransitionComplete, false);
	};

	self.removePlayLarge = function() {
		if(self.playLarge) {
			self.player.style.background = null;
			self.player.style.backgroundSize = null;
			self.player.removeChild(self.playLarge);
			self.playLarge = null;
		}
	};

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

		// only load the video if its already been playing
		if (self.controls) {
			self.video.preload = 'auto';
		}

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
		if (self.meta.startTime) {
			self.video.currentTime = self.meta.startTime;
		}

		self.updatePlayerSize();
		self.video.removeEventListener('loadedmetadata', self.initVideo, false);
	};

	self.videoReady = function() {
		self.createControls();
		self.updatePosition();
		self.setVolume(self.meta.volume);

		self.video.removeEventListener('canplay', self.videoReady, false);
		self.video.addEventListener('loadedmetadata', function() {
			self.seek();
			self.updateTime();
		}, false);
	};

	self.loadStartTime = function() {
		var hashData = parseUrlEncoded(document.location.hash.replace(/^#/, ''));
		var searchData = parseUrlEncoded(document.location.search.replace(/^\?/, ''));

		for (var attr in hashData) {
			searchData[attr] = hashData[attr];
		}

		var startTime = getStartTime(searchData);
		if (startTime) {
			self.meta.startTime = startTime;
		}
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

		self.loadStartTime();

		self.video = document.createElement('video');
		self.video = create('video', self.player);
		self.video.src = meta.formats[meta.useFormat];

		self.player.insertBefore(self.video, self.topOverlay);

		if (self.meta.autoplay) {
			focusedPlayer = this;
			self.playOrPause();
		} else {
			removeClass(self.player, 'youtube5loading');
			addClass(self.player, 'youtube5waiting');
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
		self.video.addEventListener('canplay', self.videoReady, false);

		self.infoButton.addEventListener('click', self.showOverlay, false);

		self.info.addEventListener('click', function(event) {
			if (event.target == self.info) {
				self.playOrPause();
			}
		}, false);

		self.replay.addEventListener('click', function() {
			self.playOrPause();
			self.hideOverlay();
			removeClass(self.player, 'youtube5replay');
		}, false);

		self.closeOverlay.addEventListener('click', self.hideOverlay, false);

		self.video.addEventListener('ended', function() {
			self.video.pause();
			self.showOverlay();
			addClass(self.player, 'youtube5replay');
		}, false);
	};

	self.createControls = function() {
		removeClass(self.player, 'youtube5loading');
		removeClass(self.player, 'youtube5waiting');

		self.controls = create('div', self.player, 'youtube5controls');

		// if the video is already playing, we need to set the right classname
		if (!self.video.paused) {
			self.controls.className = 'youtube5controls youtube5play';
		}

		self.playPause = create('div', self.controls, 'youtube5play-pause');
		self.timeElapsed = create('div', self.controls, 'youtube5time-elapsed');

		self.progress = create('div', self.controls, 'youtube5progress');
		self.nudge = create('div', self.progress, 'youtube5progressnudge');
		self.loaded = create('div', self.nudge, 'youtube5loaded');
		self.played = create('div', self.nudge, 'youtube5played');

		self.position = create('input', self.progress, 'youtube5position');
		self.position.type = 'range';
		self.position.min = 0;
		self.position.max = 1000;
		self.position.value = 0;

		self.timeRemaining = create('div', self.controls, 'youtube5time-remaining');

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

		self.popOut = create('div', self.controls, 'youtube5pop-out');
		self.fullscreen = create('div', self.controls, 'youtube5fullscreen');

		self.playPause.addEventListener('click', self.playOrPause, false);

		self.popOut.addEventListener('click', self.popInOrOut, false);

		self.fullscreen.addEventListener('click', self.toggleFullScreen, false);

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

		// fullscreen handler
		document.addEventListener("webkitfullscreenchange", function(event) {
			if (document.webkitIsFullScreen) {
				addClass(self.player, 'youtube5fullscreened');
			} else {
				removeClass(self.player, 'youtube5fullscreened');
			}
		}, false);

		// keyboard shortcuts
		document.addEventListener('keypress', function(event) {
			if (event.target == document.body && focusedPlayer == self && !event.shiftKey && !event.altKey && !event.ctrlKey && !event.metaKey) {
				if (event.keyCode == 32) { // space = play/pause
					event.preventDefault();
					self.playOrPause();
				} else if (event.keyCode == 102) { // f = fullscreen
					event.preventDefault();
					self.toggleFullScreen();
				} else if (event.keyCode == 112) { // p = popout
					event.preventDefault();
					self.popInOrOut();
				}
			}
		}, false);

		document.addEventListener('keydown', function(event) {
			if (event.target == document.body && focusedPlayer == self && !event.altKey && !event.ctrlKey && !event.metaKey) {
				if (event.keyCode == 37) { // left arrow = back five seconds
					event.preventDefault();

					if (event.shiftKey) {
						if (self.video.currentTime > 1) {
							self.video.currentTime -= 1;
						} else {
							self.video.currentTime = 0;
						}
					}
					else {
						if (self.video.currentTime > 5) {
							self.video.currentTime -= 5;
						} else {
							self.video.currentTime = 0;
						}
					}
				} else if (event.keyCode == 39) { // right arrow = forward five seconds
					event.preventDefault();

					if (event.shiftKey) {
						if (self.video.currentTime < self.video.duration - 1) {
							self.video.currentTime += 1;
						} else {
							self.video.currentTime = self.video.duration;
						}
					}
					else {
						if (self.video.currentTime < self.video.duration - 5) {
							self.video.currentTime += 5;
						} else {
							self.video.currentTime = self.video.duration;
						}
					}
				}
			}
		}, false);

		// timecode link handling
		document.addEventListener('click', function(event) {
			if (event.target.nodeName.toLowerCase() == 'a' && focusedPlayer == self) {
				var match = /^(?:(\d+):)?(\d{1,2}):(\d{2})$/.exec(event.target.textContent);
				if (match) {
					event.preventDefault();

					var seconds = 0;
					[3600, 60, 1].forEach(function(multiplier, i) {
						var timeValue = parseInt(match[i + 1]);
						if (timeValue) {
							seconds += multiplier * timeValue;
						}
					});

					self.video.currentTime = seconds;
					self.container.scrollIntoView();
				}
			}
		}, false);
	};

	return self;
};
