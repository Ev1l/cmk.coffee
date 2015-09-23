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
  <?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>#{body}</soap:Body>
    </soap:Envelope>
    """
getURL = (path) ->
    "https://#{host}#{path}"
    
makeRequest = (msg, path, action, body, response, cb) ->
    wrappedBody = wrapInEnvelope body

    msg.http(getURL path).header('SOAPAction', action).header('Content-type', 'text/xml; charset=utf8')
        .post(wrappedBody) (err, resp, body) ->
            unless err?
                (new xml2js.Parser()).parseString body, (err, json) ->
                    unless err?
                        body = json['soap:Envelope']['soap:Body'][0]
                        if body?
                            response_body = body[response]
                            cb(response_body) if response_body?

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
        msg.send "Processing Request for #{bdusername}"

module.exports = (robot) ->
    robot.respond /bydesign activate (.*)/i, (msg) ->
        bdusername = msg.match[1]
        bdpassword = "?"
        bdstatus = "1"
        accountmngmnt msg,bdusername,bdpassword,bdstatus
        
    robot.respond /bydesign reset (.*) (.*)/i, (msg) ->
        bdusername = msg.match[1]
        bdpassword = msg.match[2]
        bdstatus = "0"
        accountmngmnt msg,bdusername,bdpassword,bdstatus
        
    robot.respond /bydesign deactivate (.*)/i, (msg) ->
        bdusername = msg.match[1]
        bdpassword = "?"
        bdstatus = "2"
        accountmngmnt msg,bdusername,bdpassword,bdstatus
        
