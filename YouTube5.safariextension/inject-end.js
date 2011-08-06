if (/^http\:\/\/video\.(yandex(?:\-team)?\.ru)\/users\/(.+)\/view\/(.+)(?:\/)?$/i.test(document.location.href)) {
	var movies = {};

	function findMoviePlayers() {
		var roots = document.querySelectorAll('[class=h-movie-player]');
		for (var i = 0; i < roots.length; ++i) {
			var root = roots[i];
			var js = root.querySelector('script');
			if (js == null)
				continue;
			var login = /login\s*\:\s*'([^\s]+)'/.exec(js.innerHTML)[1]; // it's escaped
			var storage_directory = /storage_directory\s*\:\s*'([^\s]+)'/.exec(js.innerHTML)[1];
			if (login == null || storage_directory == null)
				continue;

			var data = {}
			data.url    = document.location.href;
			data.target = root;
			data.width  = 450;
			data.height = 337;
			data.login  = login;
			data.storageDirectory = storage_directory;

			var playerId = Math.round(Math.random()*1000000000);
			movies[playerId] = data;
		}
	}

	findMoviePlayers();

	for (var playerId in movies) {
		var p = movies[playerId];
		safari.self.tab.dispatchMessage("canLoad2", {
			url: p.url,
			playerId: playerId
		});
	}

	safari.self.addEventListener("message", function(event) {
		if (event.name === "doLoad2") {
			var playerId = event.message.playerId;
			var p = movies[playerId];
			if (p) {
				players[playerId] = newPlayer(p.target, p.width, p.height);
				safari.self.tab.dispatchMessage("loadVideo", {
					url: p.url,
					playerId: playerId,
					flashvars: null,
					storageDirectory: p.storageDirectory
				});
			}
		}
	}, true);
}
