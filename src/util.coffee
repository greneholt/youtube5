parseUrlEncoded = (text) ->
  data = {}
  if text
    pairs = text.split("&")
    pairs.forEach (pair) ->
      pair = pair.split("=")
      data[pair[0]] = decodeURIComponent(pair[1]).replace(/\+/g, " ")
  data

parseTimeCode = (text) ->
  match = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$/.exec(text)
  if match
    seconds = 0
    for multiplier, i in [3600, 60, 1]
      timeValue = parseInt(match[i + 1])
      seconds += multiplier * timeValue  if timeValue
    seconds
  else
    null

getStartTime = (params) ->
  if params.t
    parseTimeCode params.t
  else if params.time
    parseTimeCode params.time
  else if params.start
    parseTimeCode params.start
  else
    null

somePattern = (message, patterns) ->
  patterns.some (pattern) ->
    pattern.test message


getDomain = (url) ->
  match = url.match(/https?:\/\/(?:www.)?([a-z0-9\-.]+)/i)
  if match
    match[1]
  else
    ""

create = (name, parent, className) ->
  elem = document.createElement(name)
  elem.className = className  if className
  parent.appendChild elem
  elem

formatTime = (seconds) ->
  m = Math.floor(seconds / 60)
  s = Math.floor(seconds % 60)
  m = "0" + m  if m < 10
  s = "0" + s  if s < 10
  m + ":" + s

findPosition = (el) ->
  left = top = 0
  loop
    left += el.offsetLeft
    top += el.offsetTop
    break unless el = el.offsetParent
  [left, top]

addClass = (el, className) ->
  el.className += " " + className

removeClass = (el, className) ->
  el.className = el.className.replace(new RegExp("\\b" + className + "\\b"), "")

hasClass = (el, className) ->
  el.className.indexOf(className) isnt -1