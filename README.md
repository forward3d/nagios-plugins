# Forward3D Nagios plugins

This is a collection of Nagios plugins I wrote for Forward3D's systems.
Thinking they might be useful for other people, I've released them publically.

# List of plugins

Misc checks:
* [check_ftp.rb](misc/README.md#check_ftprb)
* [send_to_clickatell.rb](misc/README.md#send_to_clickatellrb)

HAProxy checks:
* [check_haproxy.rb](haproxy/README.md#check_haproxyrb)
* [check_haproxy_backlog.rb](haproxy/README.md#check_haproxy_backlogrb)

EC2 checks:
* [check_instance_status.rb](ec2/README.md#check_instance_statusrb)
* [check_elb.rb](ec2/README.md#check_elbrb)

Resque checks:
* [check_long_running_resque_jobs.rb](resque/README.md#check_long_running_resque_jobsrb)
* [check_resque_failed_jobs.rb](resque/README.md#check_resque_failed_jobsrb)
