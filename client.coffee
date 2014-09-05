args = process.argv.slice 2
usage = """

			Usage: #{'node client.js'.cyan} "To Name <toaddress@example.com>" "From Name <fromaddress@example.com>" "Test Subject" "Test Content" localhost
			
"""

if args.length isnt 5
	console.error usage
	process.exit 1

deliveremail = require './deliveremail'
fs = require 'fs'
stream = require 'stream'
moment = require 'moment'

content = new stream.PassThrough()

email =
	to: args[0]
	from: args[1]
	subject: args[2]
	content: args[3]
	host: args[4]

email.toaddress = email.to.split('<')[1].split('>')[0]
email.fromaddress = email.from.split('<')[1].split('>')[0]

deliveremail.direct email.toaddress, email.fromaddress, email.host, content, (err, message) ->
  throw err if err?
  console.log message

content.write """
From: #{email.from}
To: #{email.to}
Subject: #{email.subject}
Date: #{moment().format('ddd, DD MMM YYYY HH:mm:ss ZZ')}
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8
Content-Transfer-Encoding: 7bit

#{email.content}
"""
content.end()