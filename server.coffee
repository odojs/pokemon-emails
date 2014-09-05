simplesmtp = require 'simplesmtp'
stream = require 'stream'
require 'colors'
config = require './config.json'
deliveremail = require './deliveremail'

server = simplesmtp.createServer()
server.listen 25

console.log()
console.log '   Pokemon Emails listening on port 25'.cyan
console.log()

display = (success, conn, err) ->
  msg = "From:  #{conn.from}\n   To:    #{conn.to}"
  msg += "\n   Proxy: #{conn.forwardto}" if conn.forwardto?
  
  return console.log " √ #{msg}\n".green if success
  console.error " X #{msg}".red
  console.error "   Error: #{err}".red if err?
  console.error()

server.on 'startData', (conn) ->
  if conn.to.length isnt 1
    return conn.deny = yes
  
  for to in conn.to
    host = to.split('@')[1]
    if !(host in config.hosts)
      return conn.deny = yes
  
  conn.forwardto = config.forwardto
  conn.saveStream = new stream.PassThrough()
  deliveremail conn.forwardto, conn.from, conn.saveStream, (err, message) ->
    if !err?
      display yes, conn
    else
      display no, conn, err
    conn.cb err, message

server.on 'data', (conn, chunk) ->
  return if conn.deny? and conn.deny
  conn.saveStream.write chunk

server.on 'dataReady', (conn, cb) ->
  if conn.deny? and conn.deny
    display no, conn, 'proxy denied'
    return cb new Error 'denied' 
  conn.saveStream.end()
  conn.cb = cb