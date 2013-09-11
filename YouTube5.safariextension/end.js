// Make YouTube load a new page when navigating to a suggested video
if (location.hostname === "www.youtube.com" && window === window.top) {
	var script = document.createElement("script");
	script.text = "history.pushState = null;";
	document.body.appendChild(script);
}
