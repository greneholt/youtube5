#!/usr/bin/env coffee

# settings
FILE_ENCODING = 'utf-8'
EOL = '\n'

fs = require 'fs'
coffee = require 'coffee-script'
async = require 'async'
glob = require 'glob'
path = require 'path'

concat = (fileList, destPath) ->
  async.map fileList, (filePath, cb) ->
    fs.readFile filePath, FILE_ENCODING, (err, src) ->
      return cb err if err
      src = coffee.compile src, {bare: yes} if coffee.helpers.isCoffee(filePath)
      cb err, src
  , (err, fileContents) ->
      throw err if err
      fs.writeFileSync destPath, fileContents.join(EOL), FILE_ENCODING
      console.log "#{destPath} built."

globCopy = (pattern, destDir) ->
  glob pattern, (err, matches) ->
    throw err if err
    async.each matches, (filePath, cb) ->
      name = path.basename filePath
      copyFile filePath, path.join(destDir, name)
      cb()
    , (err) ->
      throw err if err

copyFile = (src, dest) ->
  console.log "Copied #{src} -> #{dest}"
  fs.createReadStream(src).pipe(fs.createWriteStream(dest))

globRm = (pattern) ->
  glob pattern, (err, matches) ->
    throw err if err
    async.each matches, (filePath, cb) ->
      console.log "Removed #{filePath}"
      fs.unlink filePath, cb
    , (err) ->
      throw err if err


task = process.argv[2]

if task == 'safari'
  concat [
      'src/util.js'
      'safari/inject.coffee'
      'src/player.js'
      'src/inject.js'
    ]
  , 'YouTube5.safariextension/inject.js'

  concat [
    'src/util.js'
    'src/global.js'
  ]
  , 'YouTube5.safariextension/global.js'

  globCopy 'assets/*', 'YouTube5.safariextension'
else if task == 'clean'
  globRm 'YouTube5.safariextension/*{.js,.css,.png,.gif}'
else
  console.log 'No task specified'