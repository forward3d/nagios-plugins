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