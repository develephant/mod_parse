 package = "coronasdk-parse"
 version = "1.0-2"
 source = {
    url = "git://github.com/develephant/mod_parse",
    tag = "v0.2"
 }
 description = {
    summary = "A module for working with Parse and Corona SDK.",
    detailed = [[
       This is the Client module for working with Parse.com and Corona SDK.  Learn more at parse.com and coronalabs.com.
    ]],
    homepage = "https://github.com/develephant/mod_parse",
    license = "MIT"
 }
 build = {
    type = "builtin",
    modules = { 
        mod_parse = "mod_parse.lua"
    },
    copy_directories = { "doc" }
 }