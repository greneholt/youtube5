parseUrlEncoded = (text) ->
  data = {}
  if text
    pairs = text.split("&")
    pairs.forEach (pair) ->
      pair = pair.split("=")
      data[pair[0]] = decodeURIComponent(pair[1]).replace(/\+/g, " ")
  data

parseTimeCode = (text) ->
  seconds = 0
  match = /^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$/.exec(text)
  if match
    for multiplier, i in [3600, 60, 1]
      timeValue = parseInt(match[i + 1])
      seconds += multiplier * timeValue  if timeValue
  seconds

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
