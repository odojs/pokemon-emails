// Generated by CoffeeScript 1.7.1
(function() {
  var args, content, deliveremail, email, fs, moment, stream, usage;

  args = process.argv.slice(2);

  usage = "\nUsage: " + 'node client.js'.cyan + " \"To Name <toaddress@example.com>\" \"From Name <fromaddress@example.com>\" \"Test Subject\" \"Test Content\" localhost\n";

  if (args.length !== 5) {
    console.error(usage);
    process.exit(1);
  }

  deliveremail = require('./deliveremail');

  fs = require('fs');

  stream = require('stream');

  moment = require('moment');

  content = new stream.PassThrough();

  email = {
    to: args[0],
    from: args[1],
    subject: args[2],
    content: args[3],
    host: args[4]
  };

  email.toaddress = email.to.split('<')[1].split('>')[0];

  email.fromaddress = email.from.split('<')[1].split('>')[0];

  deliveremail.direct(email.toaddress, email.fromaddress, email.host, content, function(err, message) {
    if (err != null) {
      throw err;
    }
    return console.log(message);
  });

  content.write("From: " + email.from + "\nTo: " + email.to + "\nSubject: " + email.subject + "\nDate: " + (moment().format('ddd, DD MMM YYYY HH:mm:ss ZZ')) + "\nMIME-Version: 1.0\nContent-Type: text/plain; charset=utf-8\nContent-Transfer-Encoding: 7bit\n\n" + email.content);

  content.end();

}).call(this);
