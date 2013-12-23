dofile("script/polar-player.lua")
dofile("script/ribbons.lua")
dofile("script/explode.lua")
dofile("script/timing.lua")
dofile("script/bomb.lua")

local masterAngle = 0

local filterImg = actor.LoadSprite("image/noise.png", { 400, 240 })

local function TuneInStatic()
	local tile = actor.FillScreen(filterImg, 1000)
	eapi.Animate(tile, eapi.ANIM_LOOP, 64, 0)
	local static = eapi.PlaySound(gameWorld, "sound/static.ogg", 0, 1)
	local function Fade()
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 1, 0)
		eapi.AddTimer(staticBody, 1, function() eapi.Destroy(tile) end)
		eapi.FadeSound(static, 1)
	end
	eapi.AddTimer(staticBody, 1, Fade)
end

TuneInStatic()
ribbons.Start()

local function UpdateMasterAngle(angleInc, delay)
	masterAngle = masterAngle + angleInc
	timing.Schedule(delay)
end

local function Blink(interval, intensity)
	local function BlinkClosure() ribbons.Blink(interval, intensity) end
	return timing.Immediate(BlinkClosure)
end

local function Spiral(angleInc, delay)
	for delta = 0, 359, 45 do
		bomb.Launch(masterAngle + delta)
	end
	UpdateMasterAngle(angleInc, delay)
end

local function LeftSpiral()
	Spiral(18 / math.pi, 0.1)
end

local function RightSpiral()
	Spiral(-18 / math.pi, 0.1)
end

local function ZigZag(steps, steps2, interval, angleOffset, angle)
	local dir = 1
	local counter = 0
	steps2 = steps2 or steps
	interval = interval or 0.1
	angle = angle or (18 / math.pi)
	angleOffset = angleOffset or 0
	return function()
		counter = counter + 1
		local switch = (counter > steps)
		Spiral(dir * angle, switch and interval or 0.1)
		if switch then
			masterAngle = masterAngle + angleOffset
			local tmp = steps
			steps = steps2
			steps2 = tmp
			counter = 0
			dir = -dir
		end
	end
end

local function Straight()
	Spiral(0, 0.15)
end

local function Phyllotaxis()
	bomb.Launch(masterAngle)
	UpdateMasterAngle(util.fibonacci, 0.04)
end

local function AlternatingSpiral()
	return ZigZag(2, 4, 0.2, 22.5)
end

local function AlternatingStraight()
	return ZigZag(4, 2, 0.2, 22.5, 0)
end

local function PouncingSquid()
	local max = 25
	local step = 5
	local theta = 0
	local counter = 0
	return function()
		local flip = true
		for delta = 0, 359, 60 do
			gamma = flip and theta or (max - theta)
			if flip or counter > 4 then
				bomb.Launch(delta - gamma)
				bomb.Launch(delta + gamma)
			end
			flip = not flip
		end	
		counter = counter + 1
		theta = theta + step
		if theta <= 0 or theta >= max then
			step = -step
		end
		timing.Schedule(0.1)
	end
end

local function SineWave()
	local alpha = 0
	local omega = 0
	return function ()
		for delta = 0, 359, 45 do
			bomb.Launch(masterAngle + delta)
		end
		local theta = 45 * math.sin(alpha)
		UpdateMasterAngle(theta - omega, 0.1)
		alpha = alpha + 0.2
		omega = theta
	end
end

local function BlossomingPetals()
	local counter = 0
	local flip = true
	local shape = { 0, 4, 7, 9, 11, 9, 7, 4, 0, 
			-1, -1, -1, -1, -1, -1, -1 }
	return function()
		local flip = true
		for delta = 0, 359, 30 do
			flip = not flip
			local index = flip and counter or (counter + 8)
			local gamma = shape[(index % #shape) + 1]
			if gamma >= 0 and (flip or counter > 1) then
				bomb.Launch(delta - gamma)
				bomb.Launch(delta + gamma)
			end
		end
		counter = counter + 1
		timing.Schedule(0.1)
	end
end

local function CirclesWithHoles()
	local alpha = 30
	return function()
		for beta = 0, 359, 60 do
			for delta = 0, 30, 5 do			
				bomb.Launch(beta + alpha + delta)
			end
		end
		alpha = 30 - alpha
		timing.Schedule(0.5)
	end
end

local function GetNoise(x, y, z)
	return eapi.Fractal(0.01 * x, 0.01 * y, 0.01 * z, 2, 2)
end

local function PerlinNoise()
	local delta = 0
	local progress = 0
	local arm = { x = 128, y = 0 }
	return function()
		for angle = 0, 359, 10 do
			local pos = vector.Rotate(arm, angle + delta)
			local size = GetNoise(pos.x, pos.y, progress)
			if size > 0.45 then bomb.Launch(angle + delta) end
		end
		delta = (delta + 5) % 360
		progress = progress + 12
		timing.Schedule(0.1)
	end
end

local function TheEnd()
	timing.EndLevel(1)
	input.Bind("Move")
	actor.DeleteShape(player.obj)
	local tile = actor.FillScreen(util.white, 90, util.invisible)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.Gray(1.0), 0.2, 0)
	local black = actor.FillScreen(util.white, 80, util.invisible)
	local function Quit()
		eapi.Quit()
	end
	local function Konfeti()
		util.Goto("pon-pon")
	end
	local function Puff()
		for i = -1, 1, 2 do
			local pos = { x = 0, y = i }
			explode.Puff(pos, 0.25, 95) 
		end
		eapi.AddTimer(staticBody, 1, Konfeti)
		eapi.Destroy(tile)
		bomb.Sound()
	end
	local function ShrinkHorizontal()		
		actor.ScaleTo(tile, { x = -2, y = -2 }, { x = 4, y = 4 }, 0.2)
		eapi.AddTimer(staticBody, 0.2, Puff)
	end
	local function ShrinkVertical()
		local size = { x = 800, y = 4 }
		actor.ScaleTo(tile, { x = -400, y = -2 }, size, 0.2)
		eapi.AddTimer(staticBody, 0.2, ShrinkHorizontal)
		eapi.SetColor(black, util.Gray(0))
	end
	eapi.AddTimer(staticBody, 0.2, ShrinkVertical)
	eapi.PlaySound(gameWorld, "sound/vinyl.ogg")
	eapi.SetVel(camera, vector.null)
	eapi.SetPos(camera, vector.null)
	ribbons.stopShake = true
	eapi.FadeMusic(0.2)
end

timing.patternList = {
	LeftSpiral,
	RightSpiral,
	ZigZag(8),
	ZigZag(4),
	ZigZag(2),
	Blink(0.8, 0.1),
	Straight,
	AlternatingSpiral(),
	Blink(0.6, 0.2),
	PouncingSquid(),
	AlternatingStraight(),
	Blink(0.4, 0.3),
	PerlinNoise(),
	CirclesWithHoles(),
	BlossomingPetals(),
	Phyllotaxis,
	Blink(0.1, 1.0),
	SineWave(),
	TheEnd,
}

timing.messages = {
	"You",
	"Beautiful",
	"Life",
	"Wonderful",
	"Everyone",
	"Happy",
	"Cake",
	"Delicious",
	"Candy",
	"Sweet",
	"Peace",
	"Forever",
	"Love",
}

util.Delay(staticBody, 1, player.Create, timing.Start)
actor.Cage("Reaper", 0.7, 0.6, 0.55, 0.55)
GetNoise(0, 0, 0)
timing.Progress(1)
