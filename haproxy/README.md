# Plugins for HAProxy

## check_haproxy.rb

This is a check for HAProxy, which queries the HAProxy stats HTTP interface to
determine how many backends are up or down. None of the existing plugins were able
to do things like not alert if only one of a pair of active/passive services is down,
only alert if greater than some number of backends are down, etc.

This plugin has "testspecs", which are expressions of when to alert for each
HAProxy service.

### Usage

    check_haproxy.rb -h [haproxy hostname] -p [haproxy stats port] -t [testspec]

A "testspec" is a series of four values separated by commas, and you can specify more
than one testspec by repeating the `-t` option.

### Testspec format

Here's an example of a testspec:

    web,u,3,1

The four values are, left to right:
  1. Name of the service in the HAProxy configuration file
  2. `u` or `d`: alert on UP backends or DOWN backends
  3. Warning value
  4. Critical value 

The second parameter determines whether to consider UP or DOWN backends when
examining the warning and critical values. In the example above, we would alert
WARNING if only 3 or less hosts were UP in the 'web' service, and CRITICAL if 
1 or less hosts were UP.

Another example, considering DOWN hosts:

    web,d,1,10

This would alert WARNING if a between 1 and 9 hosts were DOWN, and CRITICAL if
10 or more hosts were DOWN.

A final example, which is useful for active/passive farms where one host is
always expected to be DOWN:

    failover,u,0,0

This will alert CRITICAL if there are 0 UP hosts.

## check_haproxy_backlog.rb

This is a simple plugin for checking the number of queued connections for
a given backend in HAProxy. We have a number of farms where each backend is
configured to only handle a single connection - when all backends are busy, the frontend
connections are queued. This plugin is useful in any situation where you've limited
the number of connections your backends can accept.

### Usage

    check_haproxy_backlog.rb -H [haproxy host] -p [haproxy port] -c [critical] -w [warning] -n [name]

The arguments are self-explanatory - set `-n` to the name of the HAProxy service to observe,
and `-c` and `-w` to the critical and warning values; if the number of queued connections is
over these values, the appropriate status will be returned.