local bombImg = actor.LoadSprite("image/bomb.png", { 64, 64 })
local mineImg = actor.LoadSprite("image/mine.png", { 64, 64 })
local blurImg = actor.LoadSprite("image/blur.png", { 64, 64 })

local basePos = { x = 16, y = 0 }

local targetSize = { x = 64, y = 64 }
local targetOffset = { x = -32, y = -32 }

local xylo = { "sound/xylo1.ogg", "sound/xylo2.ogg", "sound/xylo3.ogg" }
local xylophoneTime = 0
local soundIndex = 0

local function Time()
	return eapi.GetTime(gameWorld)
end

local function PlayXylophoneSound()
	local currTime = Time()
	if currTime - xylophoneTime > 0.1 then
		eapi.PlaySound(gameWorld, xylo[soundIndex + 1])
		soundIndex = (soundIndex + 1) % 3
		xylophoneTime = currTime
	end
end

local function Explode(obj)
	actor.DeleteShape(obj)
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, obj.offset, 0.2, 0)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, obj.spriteSize, 0.2, 0)
	explode.Puff(eapi.GetPos(obj.body))
	actor.DelayedDelete(obj, 0.2)
	PlayXylophoneSound()
end

local function TouchMob(pShape, mShape)
	local obj = actor.store[mShape]
	timing.IncHits()
	bomb.ResetTime()
	obj.Touch(obj)
end

actor.SimpleCollide("Player", "Mob", TouchMob)

local white = { r = 1, g = 1, b = 1, a = 1 }
local bombStartOffset = { x = -1, y = -1 }
local bombStartSize = { x = 2, y = 2 }
local bombShape = actor.Square(8)

local function Launch(angle, life)
	local pos = vector.Rotate(basePos, angle)
	local init = {
		class = "Mob",		       
		sprite = bombImg,
		offset = bombStartOffset,
		spriteSize = bombStartSize,
		Touch = Explode,
		pos = pos,
		z = 1,
	}
	local obj = actor.Create(init)
	eapi.SetColor(obj.tile, util.invisible)
	eapi.SetAcc(obj.body, vector.Normalize(pos, 100.0))
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 32, bomb.progress)	
	eapi.AnimatePos(obj.tile, eapi.ANIM_CLAMP, targetOffset, 2, 0)
	eapi.AnimateSize(obj.tile, eapi.ANIM_CLAMP, targetSize, 2, 0)
	eapi.AnimateColor(obj.tile, eapi.ANIM_CLAMP, white, 1, 0)
	util.RotateTile(obj.tile, angle)
	bomb.progress = bomb.progress + 0.01

	local function AddShape()
		obj.bb = bombShape
		actor.MakeShape(obj)
	end

	eapi.AddTimer(obj.body, 1.8, AddShape)
end

local function GetTime()
	return Time() - bomb.lastCollision
end

local function ResetTime()
	bomb.lastCollision = Time()
	actor.ShrinkCircle()
end

local tPos1 = { x = -2, y = 0 }
local tSize1 = { x = 4, y = 4 }
local tPos2 = { x = -8, y = 0 }
local tSize2 = { x = 16, y = 360 }
local tPos3 = { x = -1024, y = 0 }
local tSize3 = { x = 2048, y = 360 }

local function TouchAnimate(tile, size, pos)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, size, 0.2, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, pos, 0.2, 0)
end

local function MineRay(obj, angle, speed)
	local z = obj.z + 0.01
	local tile = eapi.NewTile(obj.body, tPos1, tSize1, util.triangle, z)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 0.4, 0)
	util.AnimateRotation(tile, speed, angle)
	TouchAnimate(tile, tSize2, tPos2)
	local function Spread() 
		TouchAnimate(tile, tSize3, tPos3)
	end
	eapi.AddTimer(obj.body, 0.2, Spread)
end

local function CommonBurst(obj)
	MineRay(obj, 0, 100)
end

local angleOffset = 0
local function ThreeWayBurst(obj)
	for angle = 0, 240, 120 do
		MineRay(obj, angleOffset + angle, 1)
	end
	angleOffset = (angleOffset + util.fibonacci) % 360
end

local function FadeOut(tile)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 0.3, 0)
end

local function TouchMine(obj)
	FadeOut(obj.tile)
	if obj.shadow then FadeOut(obj.shadow) end
	eapi.PlaySound(gameWorld, "sound/burst.ogg")
	local function Spread()
		local z = obj.z + 0.01
		local pos = eapi.GetPos(obj.body, gameWorld)
		explode.MineBurst(pos, obj.burstAcc, z, obj.velAdjust)
	end
	eapi.AddTimer(obj.body, obj.spreadDelay, Spread)
	actor.DelayedDelete(obj, 1.2)
	actor.DeleteShape(obj)
	obj.Explode(obj)
end

local function AddShadow(obj, alpha)
	local size = { x = 64, y = 16 }
	local offset = { x = -30, y = -24 }
	obj.shadow = eapi.NewTile(obj.body, offset, size, obj.sprite, -99.211)
	eapi.Animate(obj.shadow, eapi.ANIM_LOOP, 48, 0)	
	eapi.SetColor(obj.shadow, { r = 0.0, g = 0.0, b = 0.0, a = alpha })
end

local function Mine(pos, vel, Explode, alpha, z, sprite)
	local init = {
		class = "Mob",		       
		sprite = sprite or mineImg,
		offset = { x = -32, y = -32 },
		velocity = vel or { x = -400, y = 0 },
		Explode = Explode or CommonBurst,
		bb = actor.Square(8),
		Touch = TouchMine,
		velAdjust = 400,
		spreadDelay = 0.2,
		pos = pos,
		z = z or -99.21,
	}
	alpha = alpha or 0.15
	local obj = actor.Create(init)
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 48, 0)
	if alpha > 0 then AddShadow(obj, alpha) end
	util.AnimateRotation(obj.tile, 2)
	eapi.FlipX(obj.tile, true)
	return obj
end

local function ThreeWayMine(pos, vel)
	local obj = Mine(pos, vel, ThreeWayBurst, 0)
	obj.burstAcc = { x = -1, y = 0 }
end

local function SpaceMine(pos, vel)
	local obj = Mine(pos, vel, ThreeWayBurst, 0, 10, blurImg)
	obj.burstAcc = vector.Normalize(vel, 1)
	if vector.Length(obj.burstAcc) < 0.5 then
		local angle = 360 * math.random()
		obj.burstAcc = vector.Rotate({ x = 1, y = 0 }, angle)
	end
	obj.spreadDelay = 0
	obj.velAdjust = 0
	return obj
end

state.levelScore = 0

bomb = {
	Sound = PlayXylophoneSound,
	ThreeWayMine = ThreeWayMine,
	SpaceMine = SpaceMine,
	ResetTime = ResetTime,
	lastCollision = 0,
	GetTime = GetTime,
	Launch = Launch,
	progress = 0.0,
	Mine = Mine,
}
return bomb
