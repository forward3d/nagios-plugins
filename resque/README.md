# Plugins for Resque monitoring

## check_long_running_resque_jobs.rb

This plugin checks for Resque jobs that have been running longer than the specified time. This is
useful when a Resque job may get stuck waiting for some resource, or the worker dies without cleaning
up the job in Redis.

### Usage:

    check_long_running_resque_jobs.rb -H [redis host] -p [redis port] -t [time in seconds]

You need to supply the hostname and port of the Redis server that Resque is running from. You specify
how long a job should be running before it's considered 'long-running' by supplying the `-t` option 
(note that it is specified in seconds). If you don't specify a value, jobs running for longer than
an hour are considered 'long-running'.

If any long running jobs are detected, the plugin returns a CRITICAL state.