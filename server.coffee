stream = require 'stream'
os = require 'os'
dns = require 'dns'
simplesmtp = require 'simplesmtp'
moment = require 'moment'
require 'colors'
config = require './config.json'
deliveremail = require './deliveremail'

server = simplesmtp.createServer()
server.listen 25

ip = '127.0.0.1'
for name, details of os.networkInterfaces()
  for detail in details
    if detail.family is 'IPv4' and !detail.internal
      ip = detail.address
hostname = os.hostname()

console.log()
console.log "   Pokemon Emails listening on port 25 at #{ip}".cyan
console.log()

display = (success, conn, err) ->
  msg = "From:  #{conn.from}\n   To:    #{conn.to}"
  
  msg += "\n   Proxy: #{conn.forwardto}" if conn.forwardto?
  msg += "\n   Host:  #{conn.remoteDNS}" if conn.remoteDNS?
  
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

  dns.reverse conn.remoteAddress, (err, domains) ->
    if !err? and domains.length > 0
      domain = domains[0]
      conn.remoteDNS = domain
      conn.saveStream.write "Received: from #{domain} ([#{conn.remoteAddress}]) by #{hostname} with SMTP id generated;\r\n"
    else
      conn.saveStream.write "Received: by #{hostname} with SMTP id generated;\r\n"
    conn.saveStream.write "        #{moment().format('ddd, DD MMM YYYY HH:mm:ss ZZ')} (UTC)\r\n"
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