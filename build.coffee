#!/usr/bin/env coffee

async = require 'async'
b = require './buildutils'

task = process.argv[2]

callback = (err) ->
  throw err if err

if task == 'safari'
  async.series [
    (cb) ->
      b.mkdirRecursive 'build/YouTube5.safariextension', cb

    (cb) ->
      async.parallel [
        (cb) ->
          b.concat '{src/{util,player,inject}.js,safari/inject.coffee}', 'build/YouTube5.safariextension/inject.js', cb

        (cb) ->
          b.concat '{src/{util,main,providers/*}.js,safari/main.coffee}', 'build/YouTube5.safariextension/main.js', cb

        (cb) ->
          b.globCopy 'assets/*', 'build/YouTube5.safariextension', cb

        (cb) ->
          b.globCopy 'safari/*.{html,plist}', 'build/YouTube5.safariextension', cb
      ], cb
    ], callback
else if task == 'safariback'
  b.globCopy 'build/YouTube5.safariextension/*.plist', 'safari', callback
else if task == 'chrome'
  b.concat [
      'src/util.js'
      'chrome/inject.coffee'
      'src/player.js'
      'src/inject.js'
    ]
  , 'build/chrome/inject.js', callback

  b.concat [
    'src/util.js'
    'src/main.js'
    'chrome/main.coffee'
  ]
  , 'build/chrome/main.js', callback

  b.globCopy 'assets/*', 'build/chrome', callback
else if task == 'clean'
  b.globRm 'build/YouTube5.safariextension/*', callback
  b.globRm 'build/chrome/*', callback
else
  console.log 'No task specified'