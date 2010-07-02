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

function replaceNode(insert, replace) {
    var parent = replace.parentNode;
    parent.replaceChild(insert, replace);
}

function injectVideo(video) {
    var player = document.getElementById(video.playerId);
    // every frame in a tab receives the messages, so we have to make sure the player actually exists
    if (player == null) return;
    
    var videoEl = document.createElement('video');
    videoEl.src = video.src;
    videoEl.width = player.scrollWidth;
    videoEl.height = player.scrollHeight;
    videoEl.controls = true;
    if (player.className.indexOf('youtube5-autoplay') !== -1) {
        videoEl.autoplay = true;
    } else {
        videoEl.preload = "none";
        var cdn = Math.ceil(Math.random()*4);
        videoEl.poster = "http://i" + cdn + ".ytimg.com/vi/" + video.id + "/hqdefault.jpg";
    }
    
    videoEl.addEventListener('loadedmetadata', function(event) {
        var aspectRatio = videoEl.videoWidth/videoEl.videoHeight;
        var height = Math.round(videoEl.width/aspectRatio);
        player.style.height = height + 'px';
        videoEl.height = height;
    });
    
    player.appendChild(videoEl);
}

function buildPlayer(videoId, replace, autoplay) {
    var player = document.createElement('div');
    player.className = 'youtube5-player';
    if (autoplay) {
        player.className += ' youtube5-autoplay';
    }
    player.id = 'youtube5-player-' + videoId;
    
    var width = replace.scrollWidth;
    // players normally include extra height for their controls, we don't need that height
    var height = Math.round(width/(16/9));
    player.style.width = width + 'px';
    player.style.height = height + 'px';
    
    var video = {
        id: videoId,
        playerId: player.id
    };
    
    replaceNode(player, replace);
    safari.self.tab.dispatchMessage("loadVideo", video);
}

safari.self.addEventListener("message", function(event) {
    if (event.name === "injectVideo") {
        injectVideo(event.message);
    }
}, false);

var loc = window.location.href;

if (/^http:\/\/www.youtube.com\/watch/.test(loc)) {
    var videoId = loc.match(/v=([^&]*)/)[1];
    var player = document.getElementById('watch-player');
    buildPlayer(videoId, player, true);
} else {
    var params = document.querySelectorAll('object param[name=movie], object param[name=src]');
    for (var i = 0; i < params.length; i++) {
        var param = params[i];
        var match = param.value.match(/^http:\/\/www.youtube.com\/v\/([^&]*)/);
        if (match !== null) {
            buildPlayer(match[1], param.parentNode);
        }
    }
}
