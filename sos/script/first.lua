dofile("config.lua")
dofile("script/util.lua")
dofile("script/vector.lua")
if util.FileExists("setup.lua") then
	dofile("setup.lua")
end

camera     = nil
gameWorld  = nil
staticBody = nil

state = {
	hits = 0,
	time = 0,
	blink = false, 
	progress = 1,
	scores = { },
	thisRun = { }
}
state.msgProgress = { 0, 0, 0, 0 }
if util.FileExists("saavgaam") then 
	dofile("saavgaam")
end

util.Preload()
util.Goto("startup")
