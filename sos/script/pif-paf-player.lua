local shipImg = actor.LoadSprite("image/ship.png", { 64, 64 })

local LEFT   = 1
local RIGHT  = 2
local UP     = 3
local DOWN   = 4

actor.Cage("Blocker", 1.0, 0.5)
actor.SimpleCollide("Blocker", "Player", actor.Blocker)

local animFPS = 64

local function AnimatePlayer(player, stop)
	local start = eapi.GetFrame(player.tile)
	local time = math.abs(stop - start) / animFPS
	eapi.AnimateFrame(player.tile, eapi.ANIM_CLAMP, start, stop, nil, time)
end

local function Animate(player)
	local vel = eapi.GetVel(player.body)
	if vel.x == 0 then
		AnimatePlayer(player, 16)
	elseif vel.x > 0 then
		AnimatePlayer(player, 8)
	elseif vel.x < 0 then
		AnimatePlayer(player, 24)
	end
end

local function GetDirection(moves)
	return { x = moves[RIGHT] - moves[LEFT], y = moves[UP] - moves[DOWN] }
end

local function SetSpeed(player, speed)
	if speed then player.speed = speed end
	eapi.SetVel(player.body, vector.Normalize(player.vel, player.speed))
end

local function EnableInput(player, Fn)
	input.Bind("Left", false, Fn(player, LEFT))
	input.Bind("Right", false, Fn(player, RIGHT))
	input.Bind("Up", false, Fn(player, UP))
	input.Bind("Down", false, Fn(player, DOWN))
	return player
end

local function Move(player, axis)
	return function(keyDown)
		player.moves[axis] = (keyDown and 1) or 0
		player.vel = GetDirection(player.moves)
		SetSpeed(player)
		Animate(player)
	end
end

local function FirstMove(player, axis)
	return function(keyDown)
		Move(player, axis)(keyDown)
		util.Map(eapi.Destroy, player.text)
		EnableInput(player, Move)
		actor.AddProgressCircle(player)
		bomb.ResetTime()
		timing.Start()
	end
end

local function AddHeart(obj)
	local speed = 0.2
	local z = obj.z + 0.1
	local animType = eapi.ANIM_LOOP
	local size = { x = 16, y = 16 }
	local offset = { x = -8, y = -3 }
	obj.heart = eapi.NewTile(obj.body, offset, size, util.heart, z)
	eapi.SetColor(obj.heart, { r = 0.25, g = 0.05, b = 0, a = 0.25 })
	local dstSize = { x = 8, y = 8 }
	local dstOffset = { x = -4, y = 1 }
	eapi.AnimateSize(obj.heart, animType, dstSize, speed, 0)
	eapi.AnimatePos(obj.heart, animType, dstOffset, speed, 0)
	local dstColor = { r = 0.75, g = 0.15, b = 0, a = 1.0 }
	eapi.AnimateColor(obj.heart, animType, dstColor, speed, 0)
end

local function Create()
	local obj = { z = 0,
		      speed = 300,
		      class = "Player",
		      sprite = shipImg,
		      vel = vector.null,		      
		      moves = { 0, 0, 0, 0 },
		      pos = { x = 0, y = -200 },
		      offset = { x = -32, y = -32 },
		      bb = { l = -4, r = 4, b = 2, t = 10 }, }	
	local text = "\"Arrow Keys\" - Evade"
	ribbons.ShowHelpText(obj, text)
	obj = actor.Create(obj)
	eapi.SetFrame(obj.tile, 16)
	eapi.PlayMusic("sound/music.ogg", nil, 1.0, 1.0)
	EnableInput(obj, FirstMove)
	player.obj = obj
	AddHeart(obj)
end

local function QuickFade(tile)
	eapi.SetColor(tile, util.invisible)
end

player = {
	Create = Create,
	patternTime = 6.28,
}
return player
