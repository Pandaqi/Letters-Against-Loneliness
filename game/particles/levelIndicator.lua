-- Require the JSON library for decoding purposes
local json = require( "json" )
 
-- Read the exported Particle Designer file (JSON) into a string
local filePath = system.pathForFile( "particles/particle_texture.json" )
local f = io.open( filePath, "r" )
local emitterData = f:read( "*a" )
f:close()
 
-- Decode the string
return json.decode( emitterData )