# Forward3D Nagios plugins

This is a collection of Nagios plugins I wrote for Forward3D's systems.

# List of plugins

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
