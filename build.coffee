# settings
FILE_ENCODING = 'utf-8'
EOL = '\n'

fs = require 'fs'
coffee = require 'coffee-script'
async = require 'async'
wrench = require 'wrench'

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
    'src/util.js'
    'safari/inject.coffee'
    'src/player.js'
    'src/inject.js'
  ]
  dest: 'YouTube5.safariextension/inject.js'

concat
  src: [
    'src/util.js'
    'src/global.js'
  ]
  dest: 'YouTube5.safariextension/global.js'

wrench.copyDirSyncRecursive 'assets', 'YouTube5.safariextension'