simplesmtp = require 'simplesmtp'
stream = require 'stream'
dns = require 'dns'

deliveremail = (to, from, host, stream, cb) ->
  client = simplesmtp.connect 25, host,
    greetingTimeout: 60 * 1000
    connTimeout: 60 * 1000

  sent = no
  client.on 'idle', ->
    return client.quit() if sent
    client.useEnvelope from: from, to: [to]
    sent = yes

  client.on 'rcptFailed', (addresses) -> cb new Error "Address rejected #{addresses[0]}"
  client.on 'message', -> stream.pipe client
  client.on 'ready', (success, response) ->
    return cb new Error response if !success
    cb null, response

sendemail = (to, from, stream, cb) ->
  host = to.split('@')[1]
  dns.resolveMx host, (err, addresses) ->
    throw err if err?
    return cb new Error "No MX records for #{host}" if addresses.length is 0
    addresses.sort (a,b) -> if a.priority >= b.priority then 1 else -1
    mail = addresses[0].exchange
    deliveremail to, from, mail, stream, cb


module.exports = sendemail
module.exports.direct = deliveremail