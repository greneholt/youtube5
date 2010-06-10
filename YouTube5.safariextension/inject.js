function injectVideo(video) {
    var videoPlayer=document.getElementById('watch-player');
    videoPlayer.innerHTML = video;
}

safari.self.addEventListener("message", function(event) {
    if (event.name === "injectVideo") {
        injectVideo(event.message);
    }
}, false);

safari.self.tab.dispatchMessage("loadVideo", window.location.href);