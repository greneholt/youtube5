# YouTube5 Copyright 2010 Connor McKay

# YouTube5 is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# YouTube5 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

injectVideo = (event, playerId, meta) ->
  meta.volume = getPreference('volume')
  event.target.page.dispatchMessage "injectVideo",
    playerId: playerId
    meta: meta


providers = []
newProvider = ->
  self = {}
  self.videoUrlPatterns = []
  self.blockScriptUrlPatterns = []
  self.enabled = ->
    false

  self.canLoadVideo = (message) ->
    somePattern message.url, self.videoUrlPatterns

  self.shouldBlockScript = (message) ->
    somePattern message.url, self.blockScriptUrlPatterns

  self.loadVideo = (url, playerId, flashvars, event) ->
    false

  self

canLoad = (event) ->
  message = event.message
  for provider in providers when provider.enabled()
    if message.type is "script" and provider.shouldBlockScript(message)
      event.message = "block"
      return
    else if (message.type is "plugin" or message.type is "iframe") and provider.canLoadVideo(message)
      event.message = "video"
      return
  event.message = "allow"

loadVideo = (event) ->
  url = event.message.url
  playerId = event.message.playerId
  flashvars = event.message.flashvars
  loaded = providers.some((provider) ->
    provider.enabled() and provider.loadVideo(url, playerId, flashvars, event)
  )
  unless loaded
    meta = error: "Unknown video URL<br />" + url
    injectVideo event, playerId, meta

updateVolume = (event) ->
  setPreference 'volume', event.message

safari.application.addEventListener "message", ((event) ->
  if event.name is "canLoad"
    canLoad event
  else if event.name is "loadVideo"
    loadVideo event
  else updateVolume event  if event.name is "updateVolume"
), true
