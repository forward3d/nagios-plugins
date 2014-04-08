# Plugins for Logstash monitoring

## check_logstash_receiving_events.rb

This plugin checks to see if logstash is still receiving events. A bug in logstash may cause it to stop working.

### Usage:

    check_logstash_receiving_events.rb -d [logstash directory] -b [buffer size]

You can define a directory for the logstash log files, or the default '/var/www/logstash-forwarder' will be used.
You can also define the buffer size for processing the log files, which is set to 1024 bytes by default. This check will
search backwards down the log file, looking for the 'Stopping' command, which tells us that logstash has stopped running.
