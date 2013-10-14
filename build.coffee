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
          b.compile '{src/{util,player,inject}.coffee,safari/inject.coffee}', 'build/YouTube5.safariextension/inject.js', cb

        (cb) ->
          b.compile '{src/{util,main,providers/*}.coffee,safari/main.coffee}', 'build/YouTube5.safariextension/main.js', cb

        (cb) ->
          b.globCopy 'assets/*', 'build/YouTube5.safariextension', cb

        (cb) ->
          b.globCopy 'safari/*.{html,plist}', 'build/YouTube5.safariextension', cb
      ], cb
    ], callback
else if task == 'safariback'
  b.globCopy 'build/YouTube5.safariextension/*.plist', 'safari', callback
else if task == 'chrome'
  b.compile [
      'src/util.js'
      'chrome/inject.coffee'
      'src/player.js'
      'src/inject.js'
    ]
  , 'build/chrome/inject.js', callback

  b.compile [
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