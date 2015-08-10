---Parse module for Corona SDK
-- @copyright develephant 2013-2015
-- @author Chris Byerley
-- @license MIT
-- @version 2.2.4
-- @see parse.com
local json = require("json")
local url = require("socket.url")

---Parse Class
-- @type Parse
local Parse =
{
--===========================================================================--
--== Options Start
--===========================================================================--

  --Shows a clean table/object output
  --in the main terminal.
  showStatus = false, --default: false

  --Show the http headers in the
  --Parse response status output.
  --showStatus must be 'true' as well.
  showStatusHeaders = false, --default: false

  --Output some basic information in
  --a pop-up alert. Best for phone.
  showAlert = false, --default: false

  --Output the Parse response as
  --JSON in the output console.
  showJSON = false, --default: false

  --Put 'results' outside of the 'response' key.
  --By default when you recieve multiple records,
  --the result set is put in a 'results' key on
  --the 'response' object. To instead place the
  --'results' key directly on the main object
  --set this to 'false'. You would then access
  --the results directly: `parse_response.results`
  --as opposed to: `parse_response.response.results`
  --Only works with multi-object response results.
  resultsInResponse = true, --default: true

--===========================================================================--
--== Options Done.  Nothing to see here...
--===========================================================================--

  --Various initialization
  endpoint = "https://api.parse.com/1/",
  sessionToken = nil,
  dispatcher = display.newGroup(),

  --Set up clean request queue
  requestQueue = {},

  --Parse endpoints
  NIL = nil,
  ERROR = "ERROR",
  EXPIRED = 101,
  OBJECT = "classes",
  USER = "users",
  LOGIN = "login",
  ANALYTICS = "events",
  INSTALLATION = "installations",
  CLOUD = "functions",
  FILE = "files",
  ROLE = "roles",
  PUSH = "push",

  --class constants
  USER_CLASS = "_User",
  ROLE_CLASS = "_Role",

  --action constants
  POST = "POST",
  GET = "GET",
  PUT = "PUT",
  DELETE = "DELETE",

  --upload types
  TEXT = "text/plain",
  PNG = "image/png",
  JPG = "images/jpeg",
  MOV = "video/quicktime",
  M4V = "video/x-m4v",
  MP4 = "video/mp4",

  --set these with the init method
  --not directly in the file.
  appId = nil,
  apiKey = nil
}

---Data Objects
-- @section data-oblects

---Create a new data object.
-- @string objClass The class object name.
-- @tab objDataTable The data table to create the object with.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onCreateObject( event )
--   if not event.error then
--     print( event.response.createdAt )
--   end
-- end
-- local dataTable = { ["score"] = 1200, ["cheatMode"] = false }
-- parse:createObject( "MyClass", dataTable, onCreateObject )
function Parse:createObject( objClass, objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass )
  return self:sendRequest( uri, objDataTable, Parse.OBJECT, Parse.POST, _callback )
end

---Get a data object.
-- @string objClass The object class name.
-- @string objId The object ID.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onGetObject( event )
--   if not event.error then
--     print( event.response.objectId )
--   end
-- end
-- parse:getObject( "MyClass", "objectId", onGetObject )
function Parse:getObject( objClass, objId, _callback  )
  local uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.OBJECT, Parse.GET, _callback )
end

---Update a data object.
-- @string objClass The object class name.
-- @string objId The object ID.
-- @tab objDataTable The data table to update the object with.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onUpdateObject( event )
--   if not event.error then
--     print( event.response.updatedAt )
--   end
-- end
-- local dataTable = { ["score"] = 5200, ["cheatMode"] = true }
-- parse:updateObject( "MyClass", "objectId", dataTable, onUpdateObject )
function Parse:updateObject( objClass, objId, objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass .. "/" .. objId )
  return self:sendRequest( uri, objDataTable, Parse.OBJECT, Parse.PUT, _callback )
end

---Delete a data object.
-- @string objClass The object class name.
-- @string objId The object ID.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onDeleteObject( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:deleteObject( "MyClass", "objectId", onDeleteObject )
function Parse:deleteObject( objClass, objId, _callback  )
  local uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.OBJECT, Parse.DELETE, _callback )
end

---Get objects.
-- @string objClass The object class name.
-- @tab queryTable A table based query.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onGetObjects( event )
--   if not event.error then
--     print( #event.results )
--     --OR
--     print( #events.response.results )
--   end
-- end
-- local queryTable = {
--   ["where"] = { ["score"] = { ["$lte"] = 2000 } }
-- }
-- parse:getObjects( "MyClass", queryTable, onGetObjects )
function Parse:getObjects( objClass, queryTable, _callback  )
  queryTable = queryTable or {}
  local uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass )
  return self:sendQuery( uri, queryTable, Parse.OBJECT, _callback )
end

---Link a data object to another object.
-- @string parseObjectType The Parse object type.
-- @string parseObjectId The Parse object ID.
-- @string linkField The name of the Parse `Pointer` field.
-- @string objTypeToLink The type of object that is being linked.
-- @string parseObjIdToLink The object id of the object being linked.
-- @func[opt] _callback The callback function.
-- @treturn[1] int The network request ID.
-- @treturn[2] nil No link was performed.
-- @usage
-- local function onLinkObject( event )
--   if not event.error then
--     print( event.response.updatedAt )
--   end
-- end
-- parse:linkObject( parse.USER, "user-object-id", "stats", "PlayerStat", "player-stat-object-id", onLinkFile )
function Parse:linkObject( parseObjectType, parseObjectId, linkField, objTypeToLink, parseObjIdToLink, _callback )
  local linkField = linkField
  local fileDataTable = { [linkField] = { ["className"] = objTypeToLink, ["objectId"] = parseObjIdToLink, ["__type"] = "Pointer" } }
  if parseObjectType == Parse.USER then
    return self:updateUser( parseObjectId, fileDataTable, _callback )
  else
    return self:updateObject( parseObjectType, parseObjectId, fileDataTable, _callback )
  end

  return nil
end

---Unlink a data object from another object.
-- @string parseObjectType The Parse object type.
-- @string parseObjectId The Parse object ID.
-- @string linkField The name the field with the link.
-- @func[opt] _callback The callback function.
-- @treturn[1] int The network request ID.
-- @treturn[2] nil No link was performed.
-- @usage
-- local function onUnlinkObject( event )
--   if not event.error then
--     print( event.response.updatedAt )
--   end
-- end
-- parse:unlinkObject( "Contact", "contact-object-id", "photo", onUnlinkObject )
function Parse:unlinkObject( parseObjectType, parseObjectId, linkField, _callback )
  local linkField = linkField
  local fileDataTable = { [linkField] = json.null }
  if parseObjectType == Parse.USER then
    return self:updateUser( parseObjectId, fileDataTable, _callback )
  else
    return self:updateObject( parseObjectType, parseObjectId, fileDataTable, _callback )
  end

  return nil
end

---Relations
-- @section relations

---Create a relationship.
-- @string objClass The object class name.
-- @string objId The object ID.
-- @string objField The Parse `Relation` field.
-- @tab objDataTable The data table to attach.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onAddRelation( event )
--   print( event.response.updatedAt )
-- end
-- local dataTbl = { { ["className"] = "Post", ["objectId"] = "postObjectId" } }
-- parse:createRelation( parse.USER, "userObjectId", "posts", dataTbl, onAddRelation )
function Parse:createRelation( objClass, objId, objField, objDataTable, _callback )

  local uri
  if objClass == Parse.USER then
    uri = Parse:getEndpoint( Parse.USER .. "/" .. objId )
  else
    uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass .. "/" .. objId )
  end

  local objects = {}
  for r=1, #objDataTable do
    table.insert( objects,
      { ["__type"] = "Pointer", ["className"] = objDataTable[r].className, ["objectId"] = objDataTable[r].objectId }
    )
  end

  local objField = objField
  local relationDataTable = {
    [ objField ] = { ["__op"] = "AddRelation", ["objects"] = objects }
  }

  return self:sendRequest( uri, relationDataTable, Parse.OBJECT, Parse.PUT, _callback )
end

---Remove a relationship.
-- @string objClass The object class name.
-- @string objId The object ID.
-- @string objField The object field.
-- @tab objDataTable The data table to remove.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onRemoveRelation( event )
--   print( event.response.updatedAt )
-- end
-- local dataTbl = { { ["className"] = "Post", ["objectId"] = "postObjectId" } }
-- parse:removeRelation( parse.USER, "userObjectId", "posts", dataTbl, onRemoveRelation )
function Parse:removeRelation( objClass, objId, objField, objDataTable, _callback )

  local uri
  if objClass == Parse.USER then
    uri = Parse:getEndpoint( Parse.USER .. "/" .. objId )
  else
    uri = Parse:getEndpoint( Parse.OBJECT .. "/" .. objClass .. "/" .. objId )
  end

  local objects = {}
  for r=1, #objDataTable do
    table.insert( objects,
      { ["__type"] = "Pointer", ["className"] = objDataTable[r].className, ["objectId"] = objDataTable[r].objectId }
    )
  end

  local objField = objField
  local relationDataTable = {
    [ objField ] = { ["__op"] = "RemoveRelation", ["objects"] = objects }
  }

  return self:sendRequest( uri, relationDataTable, Parse.OBJECT, Parse.PUT, _callback )
end

---File
-- @section files

---Upload a file.
-- Supports jpg, png, gif, mp4, mov, m4v
-- @tab fileMetaTable The file meta data table.
-- @string fileMetaTable.fileName The file name.
-- @param[opt=system.TemporaryDirectory] fileMetaTable.directory The base directory.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onUpload( event )
--   if event.name == "parseResponse" then --uploaded
--     print( event.response.name, event.response.url )
--   elseif event.name == "parseProgress" then --uploading
--     print( event.bytesTransferred )
--   end
-- end
-- parse:uploadFile( { ["filename"] = "photo.png", ["baseDir"] = system.DocumentsDirectory }, onUpload )
function Parse:uploadFile( fileMetaTable, _callback )

  --filename, directory
  assert( fileMetaTable.filename, "A filename is required in the meta table")

  --V 1.64 fix by Alexander Sheety
  local fileName = fileMetaTable.filename:gsub("%w*/","")
  local directory = fileMetaTable.baseDir or system.TemporaryDirectory

  --determine mime
  local contentType = self:getMimeType( fileName )

  local fileParams = self:newFileParams( contentType )

  local q = {
    requestId = network.upload(
      self.endpoint .. self.FILE .. "/" .. fileName,
      self.POST,
      function(e) self:onResponse(e); end,
      fileParams,
      fileName,
      directory,
      contentType
    ),
    requestType = self.FILE,
    _callback = _callback,
  }
  table.insert( self.requestQueue, q )

  return q.requestId

end

--V1.5 fix by https://bitbucket.org/neilhannah - Thanks!

---Link a file to another object.
-- @string parseObjectType The Parse object type.
-- @string parseObjectId The Parse object ID.
-- @string linkField The name of the linking field.
-- @string parseFileUriToLink The Parse supplied URI to the file.
-- @string parseFileUriToLinkUrl The Url to the file.
-- @func[opt] _callback The callback function.
-- @treturn[1] int The network request ID.
-- @treturn[2] nil No file was linked.
-- @usage
-- local function onLinkFile( event )
--   if not event.error then
--     print( event.response.updatedAt )
--   end
-- end
-- parse:linkFile( parse.USER, "user-object-id", "avatar", "1234567890abcdef-photo.png", onLinkFile )
function Parse:linkFile( parseObjectType, parseObjectId, linkField, parseFileUriToLink, parseFileUriToLinkUrl, _callback )
  local linkField = linkField
  local fileDataTable = { [linkField] = { ["name"] = parseFileUriToLink, ["url"] = parseFileUriToLinkUrl, ["__type"] = "File" } }
  if parseObjectType == Parse.USER then
    return self:updateUser( parseObjectId, fileDataTable, _callback )
  else
    return self:updateObject( parseObjectType, parseObjectId, fileDataTable, _callback )
  end

  return nil
end

---Unlink a file from another object.
--
-- NOTE: This does not delete the file from Parse.com, you must do that seperatly.
-- @string parseObjectType The name of the class that you want to unlink the resource from.
-- @string parseObjectId The objectId of the class object you want to unlink the resource from.
-- @string linkField The property (col) in the objClass that holds the link.
-- @func[opt] _callback The callback function.
-- @treturn[1] int The network request ID.
-- @treturn[2] nil No file was linked.
-- @usage
-- local function onUnlinkFile( event )
--   if not event.error then
--     print( event.response.updatedAt )
--   end
-- end
-- parse:unlinkFile( "Contact", "contact-object-id", "photo", onUnlinkFile )
function Parse:unlinkFile( parseObjectType, parseObjectId, linkField, _callback )
  local linkField = linkField
  local fileDataTable = { [linkField] = json.null }
  if parseObjectType == Parse.USER then
    return self:updateUser( parseObjectId, fileDataTable, _callback )
  else
    return self:updateObject( parseObjectType, parseObjectId, fileDataTable, _callback )
  end

  return nil
end

---Delete a file.
-- This method is depreciated.  **Do Not Use.**
-- You should not disclose your master key in an application.
function Parse:deleteFile( parseFileName, parseMasterKey, _callback )
  assert( parseMasterKey, "Parse Master Key is required to delete a file.")
  local uri = Parse.endpoint .. Parse.FILE .. "/" .. parseFileName
  return self:sendRequest( uri, {}, Parse.FILE, Parse.DELETE, _callback, parseMasterKey )
end

---Parse API BATCH
-- @todo Add the batch processing

---User
-- @section User

---Create a new User object.
-- @tab objDataTable The user data.
-- @func[opt] _callback The callback function.
-- @treturn int Returns a network ID.
-- @usage
-- local function onCreateUser( event )
--   if not event.error then
--     print( event.response.createdAt )
--   end
-- end
-- local userDataTable = { ["username"] = "Chris", ["password"] = "strongpw" }
-- parse:createUser( userDataTable, onCreateUser )
function Parse:createUser( objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.USER )
  return self:sendRequest( uri, objDataTable, Parse.USER, Parse.POST, _callback )
end

---Gets a User object.
-- @string objId The User object ID.
-- @func[opt] _callback The callback function.
-- @treturn int Returns a network ID.
-- @usage
-- local function onGetUser( event )
--   if not event.error then
--     print( event.response.username )
--   end
-- end
-- parse:getUser( "objectId", onGetUser )
function Parse:getUser( objId, _callback  )
  local uri = Parse:getEndpoint( Parse.USER .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.USER, Parse.GET, _callback )
end

---Get Users.
-- @tab queryTable A query table.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onGetUsers( event )
--   if not event.error then
--     print( #event.results )
--     --OR
--     print( #events.response.results )
--   end
-- end
-- local queryTable = {
--   ["where"] = { ["username"] = "Chris" },
--   ["limit"] = 5
-- }
-- parse:getUsers( queryTable, onGetUsers )
function Parse:getUsers( queryTable, _callback )
  queryTable = queryTable or {}
  local uri = Parse:getEndpoint( Parse.USER )
  return self:sendQuery( uri, queryTable, Parse.OBJECT, _callback )
end

---Log in a User.
-- @tab objDataTable The data table.
-- @func[opt] _callback The callback function.
-- @treturn[1] int The network request ID.
-- @treturn[2] nil User was not logged in.
-- @usage
-- local function onLoginUser( event )
--   if not event.error then
--     print( event.response.sessionToken )
--   end
-- end
-- parse:loginUser( { ["username"] = "Chris", ["password"] = "strongpw" }, onLoginUser )
function Parse:loginUser( objDataTable, _callback  )
  local uri = nil

  if objDataTable.authData == nil then
    uri = Parse:getEndpoint( Parse.LOGIN )
    return self:sendQuery( uri, objDataTable, Parse.LOGIN, _callback )
  else --facebook/twitter/UUID login
    uri = Parse:getEndpoint( Parse.USER )
    return self:sendRequest( uri, objDataTable, Parse.USER, Parse.POST, _callback )
  end

  return nil
end

---Update the logged in User.
-- _MUST BE LOGGED IN FIRST WITH SESSION TOKEN_
-- @string objId The User object id.
-- @tab objDataTable The object data table.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
--local function onUpdateUser( event )
--  if not event.error then
--    print( event.response.updatedAt )
--  end
--end
--local dataTable = { ["password"] = "newpassword" }
--parse:updateUser( "objectId", dataTable, onUpdateUser )
function Parse:updateUser( objId, objDataTable, _callback  )

  assert( self.sessionToken, "User must be logged in first, sessionToken cannot be nil.")

  local uri = Parse:getEndpoint( Parse.USER .. "/" .. objId )
  return self:sendRequest( uri, objDataTable, Parse.USER, Parse.PUT, _callback )
end

---Get the logged in User.
-- _MUST BE LOGGED IN FIRST WITH SESSION TOKEN_
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onGetMe( event )
--   if event.code == parse.EXPIRED then
--     print( "Session expired.  Log in.")
--   else
--     print( "Hello", event.response.username )
--   end
-- end
-- parse:getUser( onGetMe )
function Parse:getMe( _callback )

  assert( self.sessionToken, "User must be logged in first, sessionToken cannot be nil.")

  local uri = Parse:getEndpoint( Parse.USER .. "/me" )
  return self:sendRequest( uri, {}, Parse.USER, Parse.GET, _callback )
end

---Delete the logged in User.
-- _MUST BE LOGGED IN FIRST WITH SESSION TOKEN_
-- @string objId The object ID.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onDeleteUser( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:deleteUser( "objectId", onDeleteUser )
function Parse:deleteUser( objId, _callback  )

  assert( self.sessionToken, "User must be logged in first, sessionToken cannot be nil.")

  local uri = Parse:getEndpoint( Parse.USER .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.USER, Parse.DELETE, _callback )
end

---Request a lost password reset.
-- @string email The account email address.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onRequestPassword( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:requestPassword( "user@email.com", onRequestPassword )
function Parse:requestPassword( email, _callback  )
  local uri = Parse:getEndpoint( "requestPasswordReset" )
  return self:sendRequest( uri, { ["email"] = email }, Parse.USER, Parse.POST, _callback )
end

---Analytics
-- @section analytics

---Application opened event.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onAppOpened( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:appOpened( onAppOpened )
function Parse:appOpened( _callback )
  local uri = Parse:getEndpoint( Parse.ANALYTICS .. "/AppOpened" )
  local requestParams = {}
  return self:sendRequest( uri, { at = "" }, Parse.ANALYTICS, Parse.POST, _callback )
end

---Log a custom event.
-- @string eventType The event type.
-- @tab dimensionsTable The table of dimensions.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onLogEvent( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:logEvent( "Error", { ["type"] = "login" }, onLogEvent )
function Parse:logEvent( eventType, dimensionsTable, _callback )
  dimensionsTable = dimensionsTable or {}

  local uri = Parse:getEndpoint( Parse.ANALYTICS .. "/" .. eventType )
  local requestParams = {
    ["dimensions"] = dimensionsTable
  }
  return self:sendRequest( uri, requestParams, Parse.ANALYTICS, Parse.POST, _callback )
end

---Roles
-- @section roles

---Create a new role.
-- @tab objDataTable The object data.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onCreateRole( event )
--   if not event.error then
--     print( event.response.createdAt )
--   end
-- end
-- local roleDataTable = { ["name"] = "Admins", ["ACL"] = { ["*"] = { ["read"] = true } } }
-- parse:createRole( roleDataTable, onCreateRole )
function Parse:createRole( objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.ROLE )
  return self:sendRequest( uri, objDataTable, Parse.ROLE, Parse.POST, _callback )
end

---Retrieve a role.
-- @string objId The object ID.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onGetRole( event )
--   if not event.error then
--     print( event.response.ACL["*"]["read"] )
--   end
-- end
-- parse:getRole( "objectId", onGetRole )
function Parse:getRole( objId, _callback  )
  local uri = Parse:getEndpoint( Parse.ROLE .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.ROLE, Parse.GET, _callback )
end

---Push
-- @section push

-- Special thanks Ed Moyse https://bitbucket.org/edmoyse.

---Send a push message.
--
-- __NOTE: This will only work on iOS devices.__
-- @tab objDataTable The object data table for the Push message.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onSendPush(event)
--   if not event.error then
--     print(event.response)
--   end
-- end
-- local pushDataTable = {
--   ["where"] = {["channels"] = "", ["deviceType"] = "ios", ["userId"] = "objectId"},
--   ["data"] = {["alert"] = "Collect your FREE cookies!"}
-- }
-- parse:sendPush( pushDataTable, onSendPush )
function Parse:sendPush(objDataTable, _callback)
  local uri = Parse:getEndpoint( Parse.PUSH )
  return self:sendRequest( uri, objDataTable, Parse.PUSH, Parse.POST, _callback )
end

---Installations
-- @section installations

---Create a new installation.
-- @tab objDataTable The data table.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onInstallation( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- local installationDataTable = {
--   ["deviceType"] = "ios",
--   ["deviceToken"] = "device-token",
--   ["channels"] = { "" },
-- }
-- parse:createInstallation( installationDataTable, onInstallation )
function Parse:createInstallation( objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.INSTALLATION )
  return self:sendRequest( uri, objDataTable, Parse.INSTALLATION, Parse.POST, _callback ) --returns requestId
end

---Update an installation.
-- @string objId The object ID.
-- @tab objDataTable The data table.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onUpdateInstallation( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- local installationDataTable = {
--   ["channels"] = { "aNewChannel" },
-- }
-- parse:updateInstallation( installationId, installationDataTable, onUpdateInstallation )
function Parse:updateInstallation( objId, objDataTable, _callback )
  local uri = Parse:getEndpoint( Parse.INSTALLATION .. "/" .. objId )
  return self:sendRequest( uri, objDataTable, Parse.INSTALLATION, Parse.PUT, _callback ) --returns requestId
end

---Get an installation.
-- @string objId The object ID.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
function Parse:getInstallation( objId, _callback  )
  local uri = Parse:getEndpoint( Parse.INSTALLATION .. "/" .. objId )
  return self:sendRequest( uri, {}, Parse.INSTALLATION, Parse.GET, _callback ) --returns requestId
end

---Cloud
-- @section cloud

---Run cloud code.
-- @string functionName The function name.
-- @tab functionParams A table of parameters.
-- @func[opt] _callback The callback function.
-- @treturn int The network request ID.
-- @usage
-- local function onRun( event )
--   if not event.error then
--     print( event.response.value )
--   end
-- end
-- parse:run( "Hello", { ["name"] = "Chris" }, onRun )
function Parse:run( functionName, functionParams, _callback )
  functionParams = functionParams or {[""] = ""}

  local uri = Parse:getEndpoint( Parse.CLOUD .. "/" .. functionName )
  return self:sendRequest( uri, functionParams, Parse.CLOUD, Parse.POST, _callback ) --returns requestId
end

---------------------------------------------------------------------
-- Parse Module Internals
---------------------------------------------------------------------

---Build request parameters
-- @local
function Parse:buildRequestParams( withDataTable, masterKey )
  local postData = json.encode( withDataTable )
  return self:newRequestParams( postData, masterKey ) --for use in a network request
end

function Parse:sendRequest( uri, requestParamsTbl, requestType, action, _callback, masterKey )
  local requestParams = self:buildRequestParams( requestParamsTbl, masterKey )

  requestType = requestType or Parse.NIL
  action = action or Parse.POST

  local q = {
    requestId = network.request( uri, action, function(e) Parse:onResponse(e); end, requestParams ),
    requestType = requestType,
    _callback = _callback,
  }
  table.insert( self.requestQueue, q )

  return q.requestId
end

-- QUERIES --
function Parse:buildQueryParams( withQueryTable )
  local uri = ""
  for key, v in pairs( withQueryTable ) do
    if uri ~= "" then
      uri = uri .. "&"
    end

    local value = v
    if key == "where" then
      value = url.escape( json.encode( v ) )
    end

    uri = uri .. tostring( key ) .. "=" .. value

  end
  return self:newRequestParams( uri ) --for use in a network request
end

function Parse:sendQuery( uri, queryParamsTbl, requestType, _callback )
  local requestParams = self:buildQueryParams( queryParamsTbl )

  requestType = requestType or Parse.NIL
  --action = action or Parse.GET

  local queryUri = uri .. "?" .. requestParams.body
  queryUri = string.gsub( queryUri, "%s+", '%20' )

  local q = { requestId = network.request( queryUri, Parse.GET, function(e) Parse:onResponse(e); end, requestParams ),
    requestType = requestType,
    _callback = _callback,
  }
  table.insert( self.requestQueue, q )

  return q.requestId
end

-- FILES  --
function Parse:buildFileParams( withDataTable )
  local postData = json.encode( withDataTable )
  return self:newRequestParams( postData ) --for use in a network request
end

function Parse:sendFile( uri, requestParamsTbl, requestType, action )
  local requestParams = self:buildRequestParams( requestParamsTbl )

  requestType = requestType or Parse.NIL
  action = action or Parse.POST

  local q = { requestId = network.request( uri, action, function(e) Parse:onResponse(e); end, requestParams ), requestType = requestType }
  table.insert( self.requestQueue, q )

  return q.requestId
end

---Session
-- @section session

---Set the Parse provided sessionToken for all future calls that require it.
--
-- NOTE: The sessionToken is automatically set when you log a user in through Parse.
-- @string sessionToken The session token ID.
-- @treturn string The session token.
-- @usage
-- parse:setSessionToken( sessionToken )
function Parse:setSessionToken( sessionToken )
  self.sessionToken = sessionToken
  return self.sessionToken
end

---Returns the Parse sessionToken that is currently set.
-- @treturn string sessionToken The session token.
-- @usage
-- local sessionToken = parse:getSessionToken()
function Parse:getSessionToken()
  return self.sessionToken
end

---Clears the Parse sessionToken.
--
-- NOTE: This does not clear or reset a user session with Parse, it only clears the sessionToken internally, in case you need to apply a new sessionToken.
-- @usage
-- parse:clearSessionToken()
function Parse:clearSessionToken()
  self.sessionToken = nil
end

--======================================================================--
--== RESPONSE
--======================================================================--
function Parse:_debugOutput( e )
  --== Show JSON flag
  if self.showJSON then
    if e.response ~= nil then
      print( json.encode( e.response ) )
    end
  end
  --== Show Status flag
  if self.showStatus then
    if e ~= nil then
      if type(e) == 'table' then
        self:printTable( e )
      else
        print('non-table response')
      end
    end
  end
  --== Show Alert flag
  if self.showAlert then
    local msg = string.format( "Net Status: %d \n", e.httpStatusCode )
    --check error
    if e.error then
      msg = msg .. string.format( "Parse Code: %d \n", e.code )
      if e.error then
        msg = msg .. string.format( "Error: %s", e.error )
      end
    else
      msg = "Parse action was successful!"
    end

    native.showAlert( "Parsed!", msg, { "OK" } )
  end

end

--== Parse response handler
--== proceed with caution...
function Parse:onResponse( event )
  if event.phase == "ended" then

    -- Table to hold event response data
    local response_data =
    {
      bytesEstimated = event.bytesEstimated,
      bytesTransferred = event.bytesTransferred,
      isError = event.isError, --Network error
      requestId = event.requestId,
      response = event.response,
      responseHeaders = event.responseHeaders,
      responseType = event.responseType,
      status = event.status, --Network call status
      url = event.url --The original requested url
    }

    -- Table for return_data, initialized
    local return_data =
    {
      --Name of the return event
      name = "parseResponse",
      --The Parse request "type" - Parse.USER, etc.
      requestType = nil, --Set later

      response = nil, --Set later
      results = nil, --Set later (maybe)

      headers = response_data.responseHeaders or {}, --Incoming headers

      code = nil, --Parse response code (-1 if no network)
      error = nil, -- String final error code, can pass Parse errors

      networkError = response_data.isError, -- 404 is not a networkError (Bool)
      networkBytesTransferred = response_data.bytesTransferred or 0,

      httpStatusCode = response_data.status or 0 -- http status code
    }

    --check showStatusHeaders flag
    if self.showStatusHeaders == false then
      return_data.headers = nil;
    end

    -- Start working with the response
    -- first checking for Parse errors
    local HAS_ERROR = false
    if response_data and return_data then
      -- Make sure we something to work with, or else.
      assert(response_data, "response_data table missing.")
      assert(return_data, "return_data table missing.")

      local response_chk = json.decode( response_data.response )

      --Check for Parse error in decoded response
      if response_chk and type( response_chk ) == 'table' then
        if response_chk.error then
          return_data.error = response_chk.error
        end
        -- Probably has a code too.
        if response_chk.code then
          return_data.code = response_chk.code
        end
      end -- end response check if
    end

    -- Do we have an error?
    if return_data.error then
      HAS_ERROR = true --doh!
    end

    -- If error, skip the response and
    -- results since we got hosed anyway.
    if HAS_ERROR == false then

      --Transfer a 'tabled' response from Parse response
      if response_data.response ~= nil then
        return_data.response = json.decode( response_data.response )
      end

      -- Check 'resultsInResponse' flag.
      -- false means do not place the multi
      -- 'results' in the 'response' object.
      if self.resultsInResponse == false then
        if return_data.response ~= nil then
          if return_data.response.results then --we have a 'results' key
            return_data.results = return_data.response.results
            return_data.response.results = nil
          end
        end
      end
    end

    --== Debug output
    self:_debugOutput( return_data )

    --== Start preparing to respond
    local request_id = response_data.requestId

    local _callback = nil

    for r=1, #self.requestQueue do
      local req = self.requestQueue[ r ]
      if req.requestId == request_id then
        --Add the Parse request type
        return_data.requestType = req.requestType
        --set session if log in
        if return_data.requestType == 'login' then
          if return_data.response then
            if return_data.response.sessionToken then
              self.sessionToken = return_data.response.sessionToken
            else
              self.sessionToken = nil
            end
          end
        end
        --Set up callback
        _callback = req._callback
        --Remove request
        table.remove( self.requestQueue, r )
        --see ya.
        break
      end
    end

    --tidy up
    response_data = nil

    --== Send Response
    if return_data.name == 'parseResponse' then
      if _callback then
        _callback( return_data )
      else --use global
        self.dispatcher:dispatchEvent( return_data )
      end
    end

--======================================================================--
--== Progress event - uploading
--======================================================================--
  elseif event.phase == "progress" then --files

    local status = event.status or nil
    local requestId = event.requestId or 0
    local bytesTransferred = event.bytesTransferred or 0
    local url = event.url or ""

    local _callback = nil

    for r=1, #self.requestQueue do
      local request = self.requestQueue[ r ]
      if request.requestId == requestId then
        _callback = request._callback
        break
      end
    end

    if _callback then
      local e = {
        name = "parseProgress",
        requestId = requestId,
        response = nil,
        status = status,
        bytesTransferred = bytesTransferred
      }
      _callback( e )
    end
  end
end -- end-if Parse:onResponse

function Parse:newRequestParams( bodyData, masterKey )
  --set up headers
  local headers = {}
  headers["X-Parse-Application-Id"] = self.appId
  headers["X-Parse-REST-API-Key"] = self.apiKey

  --session?
  if self.sessionToken then
    headers["X-Parse-Session-Token"] = self.sessionToken
  end

  --masterkey?
  if masterKey then
    headers["X-Parse-Master-Key"] = masterKey
  end

  headers["Content-Type"] = "application/json"

  --populate parameters for the network call
  local requestParams = {}
  requestParams.headers = headers
  requestParams.body = bodyData

  return requestParams
end

-- FILE PARAMS
function Parse:newFileParams( contentType )
  --set up headers
  local headers = {}
  headers["X-Parse-Application-Id"] = self.appId
  headers["X-Parse-REST-API-Key"] = self.apiKey

  local requestParams = {}

  headers["Content-Type"] = contentType

  --populate parameters for the network call
  requestParams = {}
  requestParams.headers = headers
  requestParams.bodyType = "binary"
  requestParams.progress = true

  return requestParams
end

function Parse:getEndpoint( typeConstant )
  return self.endpoint .. typeConstant
end

function Parse:cancelRequest( requestId )
  network.cancel( requestId )
end

function Parse:getMimeType( filePath )

  local path = string.lower( filePath )
  local mime = nil

  if string.find( path, ".txt" ) ~= nil then
    mime = self.TEXT
  elseif string.find( path, ".jpg" ) ~= nil then
    mime = self.JPG
  elseif string.find( path, ".jpeg" ) ~= nil then
    mime = self.JPG
  elseif string.find( path, ".png" ) ~= nil then
    mime = self.PNG
  elseif string.find( path, ".mov" ) ~= nil then
    mime = self.MOV
  elseif string.find( path, ".mp4" ) ~= nil then
    mime = self.MP4
  elseif string.find( path, ".m4v" ) ~= nil then
    mime = self.M4V
  end

  return mime
end

function Parse:timestampToISODate( unixTimestamp )
  --2013-12-03T19:01:25Z"
  unixTimestamp = unixTimestamp or os.time()
  return os.date( "!%Y-%m-%dT%H:%M:%SZ", unixTimestamp )
end

function Parse:printTable( t, indent )
-- print contents of a table, with keys sorted. second parameter is optional, used for indenting subtables
  local names = {}
  if not indent then indent = "" end
  for n,g in pairs(t) do
      table.insert(names,n)
  end
  table.sort(names)
  for i,n in pairs(names) do
      local v = t[n]
      if type(v) == "table" then
          if(v==t) then -- prevent endless loop if table contains reference to itself
              print(indent..tostring(n)..": <-")
          else
              print(indent..tostring(n)..":")
              Parse:printTable(v,indent.."   ")
          end
      else
          if type(v) == "function" then
              print(indent..tostring(n).."()")
          else
              print(indent..tostring(n)..": "..tostring(v))
          end
      end
  end
end

function Parse:init( o )
  self.appId = o.appId
  self.apiKey = o.apiKey
end

return Parse
