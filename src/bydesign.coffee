# Description:
#   Manage ByDesign Accounts using Hubot
#
# Dependencies:
#   "xml2js": "0.1.14"
#
# Configuration:
#   HUBOT_BYDESIGN_API_HOST
#   HUBOT_BYDESIGN_API_PATH
#   HUBOT_BYDESIGN_API_ACTION
#   HUBOT_BYDESIGN_API_USERNAME
#   HUBOT_BYDESIGN_API_PASSWORD
#
# Commands:
#   hubot bydesign activate <username> - Activate account
#   hubot bydesign reset <username> <password> - Reset password of an account
#   hubot bydesign deactivate <username> - Deactivate account
#
# Author:
#   Pablo M.

xml2js = require 'xml2js'
util = require 'util'
# The domain for the API host like "api.URL.com"
host = process.env.HUBOT_BYDESIGN_API_HOST
# The path for the api "/CUSTOMERGATEWAY/personal/webservice/mdbapi.asmx"
path = process.env.HUBOT_BYDESIGN_API_PATH
# The SOAPAction call "http://www.URL.com/UserAccountManagement"
action = process.env.HUBOT_BYDESIGN_API_ACTION
apiuser = process.env.HUBOT_BYDESIGN_API_USERNAME
apipass = process.env.HUBOT_BYDESIGN_API_PASSWORD

wrapInEnvelope = (body) ->
  """
  <x:Envelope xmlns:x="http://schemas.xmlsoap.org/soap/envelope/" xmlns:www="http://www.securefreedom.com">
      <x:Body>#{body}</x:Body>
  </x:Envelope>
  """

getURL = (path) ->
  "https://#{host}#{path}"

makeRequest = (msg, path, action, body, response, cb) ->
  wrappedBody = wrapInEnvelope body
   
  msg.http(getURL path).header('SOAPAction', action).header('Content-type', 'text/xml; charset=utf-8')
    .post(wrappedBody) (err, resp, body) ->         
      parser = new xml2js.Parser({ explicitArray : false, ignoreAttrs : true })
      parser.parseString body, (err, json) ->
        jstring = JSON.stringify(json)         
        js = JSON.parse(jstring)

        #example of grabbing objects that match some key and value in JSON
        #return an array of objects according to key, value, or key and value matching
        getObjects = (obj, key, val) ->
          objects = []
          for i of obj
            if !obj.hasOwnProperty(i)
              continue
            if typeof obj[i] == 'object'
              objects = objects.concat(getObjects(obj[i], key, val))
            else if i == key and obj[i] == val or i == key and val == ''
              objects.push obj
            else if obj[i] == val and key == ''
            #only add if the object is not already in the array
              if objects.lastIndexOf(obj) == -1
                objects.push obj
          objects

        #return an array of values that match on a certain key
        getValues = (obj, key) ->
          objects = []
          for i of obj
            if !obj.hasOwnProperty(i)
              continue
            if typeof obj[i] == 'object'
              objects = objects.concat(getValues(obj[i], key))
            else if i == key
              objects.push obj[i]
          objects

        #return an array of keys that match on a certain value
        getKeys = (obj, val) ->
          objects = []
          for i of obj
            if !obj.hasOwnProperty(i)
              continue
            if typeof obj[i] == 'object'
              objects = objects.concat(getKeys(obj[i], val))
            else if obj[i] == val
              objects.push i
          objects
        
        #Examples
        #console.log getObjects(js, 'Success', '1')
        #returns 1 object where a key names Success has the value 1
        
        #example of grabbing objects that match some key in JSON
        #console.log getObjects(js, 'Message', '')
   
        #example of grabbing objects that match some value in JSON
        #console.log getObjects(js, '', '1')

        #example of grabbing objects that match some key in JSON
        #console.log getObjects(js, 'Sucess', '')

        #example of grabbing values from any key passed in JSON
        #console.log getValues(js, 'Message')

        #example of grabbing keys by searching via values in JSON
        #console.log getKeys(js, '1')

        if (err)
          msg.send "An error occurred"
          console.log "An error occurred: #{err}"
        else
          msg.send "#{getValues(js, 'Message')}"
          console.log "Action completed succesfully with message #{getValues(js, 'Message')} Request initated by #{msg.envelope.user.name}"

accountmngmnt = (msg,bdusername,bdpassword,bdstatus) ->
  if bdusername?
    body = """
        <www:UserAccountManagement>
            <www:Credentials>
                <www:Username>#{apiuser}</www:Username>
                <www:Password>#{apipass}</www:Password>
            </www:Credentials>
            <www:UserNames>
                <www:UserNames>
                    <www:UserName>#{bdusername}</www:UserName>
                </www:UserNames>
            </www:UserNames>
            <www:Password>#{bdpassword}</www:Password>
            <www:AccountStatus>#{bdstatus}</www:AccountStatus>
        </www:UserAccountManagement>
        """
    makeRequest msg, path, action, body, 'Success', (obj) ->


module.exports = (robot) ->
  robot.respond /bydesign activate (.*)/i, (msg) ->
    bdusername = msg.match[1]
    bdpassword = "?"
    bdstatus = "1"
    accountmngmnt msg,bdusername,bdpassword,bdstatus
    robot.logger.info "Processing BD activation request from #{msg.envelope.user.name}, Data: #{msg} #{bdusername} #{bdpassword} #{bdstatus}"

  robot.respond /bydesign reset (.*) (.*)/i, (msg) ->
    bdusername = msg.match[1]
    bdpassword = msg.match[2]
    bdstatus = "0"
    accountmngmnt msg,bdusername,bdpassword,bdstatus
    robot.logger.info "Processing BD PW reset request from #{msg.envelope.user.name}, Data: #{msg} #{bdusername} #{bdpassword} #{bdstatus}"
        
  robot.respond /bydesign deactivate (.*)/i, (msg) ->
    bdusername = msg.match[1]
    bdpassword = "?"
    bdstatus = "2"
    accountmngmnt msg,bdusername,bdpassword,bdstatus
    robot.logger.info "Processing BD deactivation request from #{msg.envelope.user.name}, Data: #{msg} #{bdusername} #{bdpassword} #{bdstatus}"
