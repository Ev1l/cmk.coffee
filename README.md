# cmk.coffee

This script allows you to Acknowledge a service or host alert, set downtime, schedule a service recheck, mute alerts for a particular service, and silence all alerts on Check_Mk and Nagios via Hubot. 

See [`src/cmk.coffee`](src/cmk.coffee) for full documentation.

## Commands and Syntax

```
/cmk ack <host> "<service>" <descr> - acknowledge service (Don't forget the quotes)
/cmk ack <host> <descr> - acknowledge host
/cmk all_alerts_off - useful in emergencies. warning: disables all alerts, not just bot alerts
/cmk all_alerts_on - turn alerts back on
/cmk down <host> "<service>" <minutes> <descr> - schedule downtime for the service (Don't forget the quotes)
/cmk down <host> <minutes> <descr> - schedule downtime for the host
/cmk mute <host> "<service>" <minutes> - delay the next service notification (Don't forget the quotes)
/cmk recheck <host> "<service>" - force a recheck of a service (Don't forget the quotes)
```
