# settings
FILE_ENCODING = 'utf-8'
EOL = '\n'

fs = require 'fs'
coffee = require 'coffee-script'
async = require 'async'
glob = require 'glob'
path = require 'path'

module.exports = utils = {}

utils.compile = (pattern, dest, callback) ->
  glob pattern, {nosort: true}, (err, matches) ->
    return callback err if err
    async.map matches, (filePath, cb) ->
      fs.readFile filePath, FILE_ENCODING, cb
    , (err, fileContents) ->
      return callback err if err
      coffeeSource = fileContents.join(EOL)
      try
        jsSource = coffee.compile coffeeSource, {bare: yes}
      catch err
        useColors = process.stdout.isTTY and !process.env.NODE_DISABLE_COLORS;
        message = coffee.helpers.prettyErrorMessage err, '[COMBINED]', coffeeSource, useColors
        return callback new SyntaxError(message)
      fs.writeFile dest, jsSource, FILE_ENCODING, (err) ->
        return callback err if err
        console.log "Concat #{matches.join(', ')} -> #{dest}"
        callback()

utils.globCopy = (pattern, destDir, callback) ->
  glob pattern, (err, matches) ->
    return callback err if err
    async.each matches, (filePath, cb) ->
      name = path.basename filePath
      utils.copyFile filePath, path.join(destDir, name), cb
    , callback

utils.copyFile = (src, dest, callback) ->
  try
    fs.createReadStream(src).on('end', ->
      console.log "Copied #{src} -> #{dest}"
      callback()
    ).on('error', (err) ->
      callback(err)
    ).pipe(fs.createWriteStream(dest))
  catch err
    callback(err)

utils.globRm = (pattern, callback) ->
  glob pattern, (err, matches) ->
    return callback err if err
    async.each matches, (filePath, cb) ->
      fs.unlink filePath, (err) ->
        return cb err if err
        console.log "Removed #{filePath}"
        cb()
    , callback

# eventally switch to this: https://npmjs.org/package/mkdirp

utils.mkdirRecursive = (dir, mode, callback) ->
  dir = path.normalize(dir)
  if typeof mode is 'function'
    callback = mode
    mode = null

  mode = 0o777 unless mode

  mkdirRecursiveHelper dir, mode, (err) ->
    return callback err if err
    console.log "Created #{dir}"
    callback()

mkdirRecursiveHelper = (dir, mode, callback) ->
  fs.mkdir dir, mode, (err) ->
    if err
      if err.code is "ENOENT"
        parentDir = path.dirname dir
        mkdirRecursiveHelper parentDir, mode, (err) ->
          return callback err if err
          mkdirRecursiveHelper dir, mode, callback
      else if err.code is "EEXIST"
        callback()
      else
        callback err
    else
      callback()