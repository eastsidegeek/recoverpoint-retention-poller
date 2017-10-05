# recoverpoint-retention-poller
Polls RecoverPoint clusters for required vs actual journal retention

This is a simple Perl script that interacts with RecoverPoint's RESTful API. It's based on the RP 4.4 API (oldest currently under support as of Oct 2017 for maximum backward compatibility). It's written in Perl and uses only libraries that come by default with Strawberry Perl for Windows or most Linux distros.

Usage is pretty simple. Create a file called rp-systems.config in the working folder. File should have one line per RP cluster you want to query using format
RP cluster IP,username,password

You can also start a line in rp-systems.config with # to create comments

Run the script with no arguments. It will find all consistency group copies on all clusters and report the following as an Excel-importable CSV:
RP cluster IP, CG Name, Copy Name, Required Protection Window, Current Protection Window, Predicted Protection Window

All protection windows are listed in microseconds so scale appropriately.
