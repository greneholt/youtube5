function replaceNode(insert, replace) {
    var parent = replace.parentNode;
    parent.replaceChild(insert, replace);
}

function injectVideo(url) {
    var video = document.createElement('video');
    video.src = url;
    video.width = 640;
    video.height = 360;
    video.controls = true;
    video.autoplay = true;
    
    var player = document.getElementById('youtube5-player');
    player.appendChild(video);
}

safari.self.addEventListener("message", function(event) {
    if (event.name === "injectVideo") {
        injectVideo(event.message);
    }
}, false);

var loc = window.location.href;
var player;
var videoLocation;

if (/^http:\/\/www.youtube.com\/watch/.test(loc)) {
    player = document.getElementById('watch-player');
    videoLocation = loc;
} else if (/^http:\/\/www.youtube.com\/user/.test(loc)) {
    player = document.getElementById('playnav-player');
    var videoId = document.body.innerHTML.match(/playnav\.setVideoId\('([^']*)'\);/)[1];
    videoLocation = "http://www.youtube.com/watch?v=" + videoId;
    // kill onclick, it loads a new video using ajax which won't work
    var thumbs = document.querySelectorAll('a.video-thumb img, a.playnav-item-title');
    for (var i = 0; i < thumbs.length; i++) {
        thumbs[i].onclick = null;
    }
}

var player5 = document.createElement('div');
player5.id = 'youtube5-player';
replaceNode(player5, player);

safari.self.tab.dispatchMessage("loadVideo", videoLocation);