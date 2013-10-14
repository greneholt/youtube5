# YouTube5 Copyright 2010 Connor McKay

# YouTube5 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# YouTube5 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

providers = []
newProvider = ->
  self = {}
  self.videoUrlPatterns = []
  self.blockScriptUrlPatterns = []
  self.enabled = ->
    false

  self.canLoadVideo = (requestInfo) ->
    somePattern requestInfo.url, self.videoUrlPatterns

  self.shouldBlockScript = (requestInfo) ->
    somePattern requestInfo.url, self.blockScriptUrlPatterns

  self.loadVideo = (url, flashvars, callback) ->
    false

  self

canLoad = (requestInfo) ->
  for provider in providers when provider.enabled()
    if requestInfo.type is 'script' and provider.shouldBlockScript(requestInfo)
      return 'block'
    else if (requestInfo.type is 'plugin' or requestInfo.type is 'iframe') and provider.canLoadVideo(requestInfo)
      return 'video'
  return 'allow'

loadVideo = (url, flashvars, callback) ->
  loaded = providers.some((provider) ->
    provider.enabled() and provider.loadVideo(url, flashvars, callback)
  )
  unless loaded
    meta = error: "Unknown video URL<br />#{url}"
    callback meta

updateVolume = (level) ->
  setPreference 'volume', level
