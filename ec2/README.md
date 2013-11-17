# Plugins for EC2 monitoring

## check_instance_status.rb

This plugin checks the EC2 status checks for a given instance. They appear in the EC2 console 
under the tab "Status Checks" as "System reachability check" and "Instance reachability check".
They are used by Amazon to indicate there's a problem with the underlying host the instance
is running on.

### Usage

    check_instance_status.rb -a [access key] -s [secret key] -i [instance id] -r [region]

You will need to create an IAM user for the plugin, and supply its Access Key ID and Secret
Access Key to the `-a` and `-s` options. The following IAM policy will give the user enough
rights to check the instance's status:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "ec2:DescribeInstanceStatus"
          ],
          "Sid": "Stmt1381237703000",
          "Resource": [
            "*"
          ],
          "Effect": "Allow"
        }
      ]
    }

If either of the two EC2 checks fails, the plugin will return a critical state.

## check_elb.rb

This plugin will check a given instance is present in at least one ELB, and that it is
healthy in every ELB it is in.

### Usage

    check_elb.rb -a [access key] -s [secret key] -i [instance id] -r [region]

You will need to create an IAM user for the plugin, and supply its Access Key ID and
Secret Access Key to the `-a` and `-s` options. The following IAM policy will give the user
enough rights to access the ELB statuses:

    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "elasticloadbalancing:DescribeInstanceHealth",
            "elasticloadbalancing:DescribeLoadBalancers"
          ],
          "Sid": "Stmt1380714345000",
          "Resource": [
            "*"
          ],
          "Effect": "Allow"
        }
      ]
    }

If the instance is unhealthy in an ELB, the plugin will return a CRITICAL state. If the instance
is not in any ELBs, the plugin will return the UNKNOWN state.

This plugin should be expanded to test that the instance is in a specified list of ELBs, rather
than just present in at least one.