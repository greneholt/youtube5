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

(function() {
    var player = document.getElementById('watch-player');
    var player5 = document.createElement('div');
    player5.id = 'youtube5-player';
    replaceNode(player5, player);
})();

safari.self.tab.dispatchMessage("loadVideo", window.location.href);