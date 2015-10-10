# Description:
#
#   Script for manipulating Check_MK and Nagios
#
# Configuration:
#   HUBOT_CMK_URL - https://<USERNAME>:<PASSWORD>@<CHECK_MK_URL>/<SITENAME>/nagios/cgi-bin
#
# Commands:
#   hubot cmk ack <host> <descr> - acknowledge host
#   hubot cmk ack <host> "<service>" <descr> - acknowledge service (Don't forget the quotes)
#   hubot cmk down <host> <minutes> <descr> - schedule downtime for the host
#   hubot cmk down <host> "<service>" <minutes> <descr> - schedule downtime for the service (Don't forget the quotes)
#   hubot cmk mute <host> "<service>" <minutes> - delay the next service notification (Don't forget the quotes)
#   hubot cmk recheck <host> "<service>" - force a recheck of a service (Don't forget the quotes)
#   hubot cmk all_alerts_off - useful in emergencies. warning: disables all alerts, not just bot alerts
#   hubot cmk all_alerts_on - turn alerts back on
#
cmk_url = process.env.HUBOT_CMK_URL
process.env['NODE_TLS_REJECT_UNAUTHORIZED'] = '0';

# Format Dates properly
formatDate = (date) ->
  dateStamp = [date.getFullYear(), (date.getMonth() + 1), date.getDate()].join("-")
  timeStamp = [date.getHours(), date.getMinutes(), date.getSeconds()].join(":")
  RE_findSingleDigits = /\b(\d)\b/g
  timeStamp = dateStamp + "%20" + timeStamp


# Places a `0` in front of single digit numbers.
  timeStamp = timeStamp.replace( RE_findSingleDigits, "0$1" )
  timeStamp.replace /\s/g, ""

# Start Listening for commands
module.exports = (robot) ->
  robot.respond /cmk ack(nowledge)? (\S+) (.*)/i, (msg) ->
    host = msg.match[2]
    message = msg.match[3] || ""
    robot.logger.info "#{msg.envelope.user.name} acked #{host}"
    fullmsg = "#{message} - Submitted by #{msg.envelope.user.name} via Bbot"
    call = "cmd.cgi"
    data = "cmd_typ=33&host=#{host}&cmd_mod=2&sticky_ack=on&com_author=#{msg.envelope.user.name}&send_notification=on&com_data=#{encodeURIComponent(fullmsg)}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Your acknowledgement was received by Check_MK"

  robot.respond /cmk ack(nowledge)? (\S+) "([\w\d\s,\.]*)" (.*)/i, (msg) ->
    host = msg.match[2]
    service = msg.match[3]
    message = msg.match[4] || ""
    robot.logger.info "#{msg.envelope.user.name} acked #{host}:#{service}"
    fullmsg = "#{message} - Submitted by #{msg.envelope.user.name} via Bbot"
    call = "cmd.cgi"
    data = "cmd_typ=34&host=#{host}&service=#{service}&cmd_mod=2&sticky_ack=on&com_author=#{msg.envelope.user.name}&send_notification=on&com_data=#{encodeURIComponent(fullmsg)}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Your acknowledgement was received by Check_MK"

  robot.respond /cmk (down|downtime) ([^:\s]+) (\d+) (.*)/i, (msg) ->
    host = msg.match[2]
    minutes = msg.match[3] || 30
    message = msg.match[4] || ""
    downstart = new Date()
    downstop  = new Date(downstart.getTime() + (1000 * 60 * minutes))
    downstart_str = formatDate(downstart)
    downstop_str = formatDate(downstop)
    robot.logger.info "#{msg.envelope.user.name} scheduled downtime for #{host} for #{minutes}min from #{downstart_str} to #{downstop_str} b/c #{message}"
    fullmsg = "#{message} - Submitted by #{msg.envelope.user.name} via Bbot"
    call = "cmd.cgi"
    data = "cmd_typ=55&cmd_mod=2&host=#{host}&fixed=1&start_time=#{downstart_str}&end_time=#{downstop_str}&com_data=#{encodeURIComponent(fullmsg)}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Downtime for #{host} for #{minutes}m"

  robot.respond /cmk (down|downtime) (\S+) "([\w\d\s,\.]*)" (\d+[dhm]?) (.*)/i, (msg) ->
    # d=days h=hours m=min default m
    parsetime = (time) =>
      lastchar = time[-1..]
      if lastchar == 'd'
        return time[..-2] * 60 * 24
      else if lastchar == 'h'
        return time[..-2] * 60
      else if lastchar == 'm'
        return time[..-2]
      else
        return time
    host = msg.match[2]
    service = msg.match[3]
    duration = msg.match[4] || 30
    message = msg.match[5] || ""
    downstart = new Date()
    minutes = parsetime(duration)
    downstop  = new Date(downstart.getTime() + (1000 * 60 * minutes))
    downstart_str = formatDate(downstart)
    downstop_str = formatDate(downstop)
    robot.logger.info "#{msg.envelope.user.name} scheduled downtime for #{host}:#{service} for #{minutes}min from #{downstart_str} to #{downstop_str} b/c #{message}"
    fullmsg = "#{message} - Submitted by #{msg.envelope.user.name} via Bbot"
    call = "cmd.cgi"
    data = "cmd_typ=56&cmd_mod=2&host=#{host}&service=#{service}&fixed=1&start_time=#{downstart_str}&end_time=#{downstop_str}&com_data=#{encodeURIComponent(fullmsg)}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Downtime for #{host}:#{service} for #{minutes}m"

  robot.respond /cmk mute (\S+) "([\w\d\s,\.]*)" (\d+)/i, (msg) ->
    host = msg.match[1]
    service = msg.match[2]
    minutes = msg.match[3] || 30
    robot.logger.info "#{msg.envelope.user.name} asked to mute #{host}:#{service}"
    call = "cmd.cgi"
    data = "cmd_typ=9&cmd_mod=2&host=#{host}&service=#{service}&not_dly=#{minutes}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Muting #{host}:#{service} for #{minutes}m"

  robot.respond /cmk recheck (\S+) "([\w\d\s,\.]*)"/i, (msg) ->
    host = msg.match[1]
    service = msg.match[2]
    robot.logger.info "#{msg.envelope.user.name} forced recheck of #{host}:#{service}"
    call = "cmd.cgi"
    d = new Date()
    start_time = "#{d.getMonth()+1}-#{d.getDate()}-#{d.getFullYear()} #{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"
    data = "cmd_typ=7&cmd_mod=2&host=#{host}&service=#{service}&force_check=on&start_time=#{start_time}"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Scheduled to recheck #{host}:#{service} at #{start_time}"

  robot.respond /cmk (all_alerts_off|stfu|shut up)/i, (msg) ->
    robot.logger.info "#{msg.envelope.user.name} disable notifications"
    call = "cmd.cgi"
    data = "cmd_typ=11&cmd_mod=2"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Ok, all alerts off. (this disables ALL alerts, not just mine.)"

  robot.respond /cmk all_alerts_on/i, (msg) ->
    robot.logger.info "#{msg.envelope.user.name} enabled notifications"
    call = "cmd.cgi"
    data = "cmd_typ=12&cmd_mod=2"
    cmk_post msg, call, data, (res) ->
      if res.match(/Your command request was successfully submitted to Nagios for processing/)
        msg.send "Ok, alerts back on"

cmk_post = (msg, call, data, cb) ->
  msg.http("#{cmk_url}/#{call}")
    .header('accept', '*/*')
    .header('User-Agent', "Hubot/#{@version}")
    .post(data) (err, res, body) ->
      cb body
