#!/usr/bin/env coffee

async = require 'async'
b = require './buildutils'

task = process.argv[2]

callback = (err) ->
  throw err if err

if task is 'safari'
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
else if task is 'safariback'
  b.globCopy 'build/YouTube5.safariextension/*.plist', 'safari', callback
else if task is 'chrome'
  async.series [
    (cb) ->
      b.mkdirRecursive 'build/chrome', cb

    (cb) ->
      async.parallel [
        (cb) ->
          b.compile '{src/*.coffee,src/providers/*.coffee,chrome/inject.coffee}', 'build/chrome/inject.js', cb

        (cb) ->
          b.globCopy 'assets/*', 'build/chrome', cb

        (cb) ->
          b.globCopy 'chrome/manifest.json', 'build/chrome', cb
      ], cb
    ], callback
else if task is 'clean'
  b.globRm 'build/YouTube5.safariextension/*', callback
  b.globRm 'build/chrome/*', callback
else
  console.log 'No task specified'