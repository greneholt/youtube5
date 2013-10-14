getPreference = (name) ->
  safari.extension.settings[name]

setPreference = (name, value) ->
  safari.extension.settings[name] = value