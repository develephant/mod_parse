 package = "coronasdk-parse"
 version = "1.0-1"
 source = {
    url = "git://github.com/develephant/Coronium-GS-Client",
    tag = "v0.1"
 }
 description = {
    summary = "A module for working with Parse and Corona SDK.",
    detailed = [[
       This is the Client module for working with Parse.com and Corona SDK.  Learn more at parse.com and coronalabs.com.
    ]],
    homepage = "https://github.com/develephant/Coronium-GS-Client",
    license = "MIT" -- or whatever you like
 }
 build = {
    type = "builtin",
    modules = { 
        mod_parse = "mod_parse.lua"
    },
    copy_directories = { "doc" }
 }