# settings
FILE_ENCODING = 'utf-8'
EOL = '\n'

fs = require 'fs'
coffee = require 'coffee-script'
async = require 'async'
wrtench = require 'wrench'

concat = (opts) ->
  fileList = opts.src
  distPath = opts.dest

  async.map fileList, (filePath, cb) ->
    fs.readFile filePath, FILE_ENCODING, (err, src) ->
      src = coffee.compile src, {bare: yes} if coffee.helpers.isCoffee(filePath)
      cb err, src
  , (err, fileContents) ->
      throw err if err
      fs.writeFileSync distPath, fileContents.join(EOL), FILE_ENCODING
      console.log "#{distPath} built."

copy = (src, dest) ->
  fs.createReadStream(src).pipe(fs.createWriteStream(dest))

concat
  src: [
    'common/util.js'
    'safari/inject.coffee'
    'common/player.js'
    'common/inject.js'
  ]
  dest: 'YouTube5.safariextension/inject.js'

copy 'common/global.js', 'YouTube5.safariextension/global.js'