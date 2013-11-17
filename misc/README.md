# Misc plugins 

## check_ftp.rb

This plugin will connect an FTP server and perform the following steps:
1. Log in
2. Switch to passive mode
3. Upload a file
4. List the contents of the directory, look for the file it uploaded
5. Delete the file

If any one of these steps failed, the plugin will return a critical state and an description of what
the problem was.

### Usage

    check_ftp.rb -H [ftp hostname] -p [ftp port] -u [username] -P [password] -v

Arguments are as follows:
* `-H` and `-p` specify the FTP server to connect to
* `-u` and `-P` specify the username and password to log in with
* `-v` will turn on verbose mode when an error is encountered - don't use this in Nagios as
  the output will be truncated. Use it when the plugin returns an error and you need to triage it.

### Notes

The plugin will create a file at `/tmp/ftpfile` to upload, and the file will be placed in the
root of the FTP server and named `nagios_test`.

## check_github_status.rb

This is a very simple Nagios plugin for checking Github's [Status API](https://status.github.com/api).

Github's Status API returns 3 states - good (which we take to mean OK), minor (which we report as WARNING), 
and major (which we report as CRITICAL).

### Usage

    check_github_status.rb

The plugin doesn't take any arguments.

## send_to_clickatell.rb

This plugin sends notifications to [Clickatell's SMS service](http://www.clickatell.com/) via their HTTPS API.
To use this plugin you will need a Clickatell username, password, and API key.

### Usage

    send_to_clickatell.rb -a [apikey] -u [username] -p [password] -m [mobile number] -M [message]

`-a`, `-u` and `-p` are from your Clickatell account. `-m` is the mobile number to send the message to (you
should template this with `$CONTACTPAGER$` in your Nagios configuration, see below). `-M` is the message to send,
which you should also template in the Nagios configuration.

The full scope of configuring a notification plugin is beyond this document; see the Nagios documentation.
Configure the Nagios command in your Nagios configuration file with something like this:

    define command {
      command_line /usr/lib/nagios/plugins/send_to_clickatell.rb -a [apikey] -u [username] -p [password] -m $CONTACTPAGER$ -M "NAGIOS: $NOTIFICATIONTYPE$: Host: $HOSTALIAS$ Service: $SERVICEDESC$ State: $SERVICESTATE$ Info: $SERVICEOUTPUT$"
      command_name send_to_clickatell
    }

Amend the message to suit your needs. Make sure your contacts have their mobile number specified in `contact_pager`.
Now you can assign `send_to_clickatell` to any of your services you want to notify by text message for.

### Notes

This plugin will only try to use a maximum of 3 SMS messages to send the notification, so keep the message short and to
the point. Theoretically the SMS service could support more concatenated messages, but 3 is the maximum
Clickatell advise you use.

The plugin will log to syslog with the program name `send_to_clickatell`. This is helpful if you need to debug
why a notification didn't get sent, and what notifications were sent, at what time, and to who.

