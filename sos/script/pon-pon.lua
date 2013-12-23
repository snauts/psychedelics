dofile("script/flow.lua")
dofile("script/bomb.lua")
dofile("script/timing.lua")
dofile("script/ribbons.lua")
dofile("script/explode.lua")
dofile("script/pon-pon-player.lua")

local function TuneIn()
	local speed = 0.2
	local flyTime = 2 - 2 * speed
	local size = { x = 4, y = 4 }
	local body = eapi.NewBody(gameWorld, vector.null)
	local black = actor.FillScreen(util.white, 999, util.Gray(0))

	local dot = { }
	for i = -1, 1, 2 do
		local dst = { x = -2, y = -2 }
		local pos = { x = -2, y = i * 240 }
		dot[i] = eapi.NewTile(body, pos, size, util.white, 1000)
		eapi.AnimatePos(dot[i], eapi.ANIM_CLAMP, dst, flyTime, 0)
	end
	local function FadeOut()		
		eapi.AnimateColor(dot[1], eapi.ANIM_CLAMP, util.invisible, 1, 0)
		util.DelayedDestroy(body, 1)
		eapi.Destroy(dot[-1])
		eapi.Destroy(black)
	end
	local function ExpandVertically()
		local offset = vector.Scale(actor.screenSize, -0.5)
		actor.ScaleTo(dot[1], offset, actor.screenSize, speed)
		eapi.AddTimer(staticBody, speed, FadeOut)
	end
	local function ExpandHorizontally()
		local offset = { x = -400, y = -2 }
		actor.ScaleTo(dot[1], offset, { x = 800, y = 4 }, speed)
		eapi.AddTimer(staticBody, speed, ExpandVertically)
		eapi.PlayMusic("sound/caravan.ogg", nil, 1.0, 1.0)
		eapi.PlaySound(gameWorld, "sound/burst.ogg")
		eapi.SetColor(dot[1], util.Gray(1.0))
	end
	eapi.AddTimer(staticBody, flyTime, ExpandHorizontally)
end

local function MinePattern(timeList)
	local timeIndex = 1
	return function()
		bomb.Mine({ x = 500, y = -120 })
		timing.Schedule(timeList[timeIndex])
		timeIndex = timeIndex + 1
		if timeIndex > #timeList then
			timeIndex = 1
		end
	end
end

local function FadeOut(tile)
	local color = eapi.GetColor(tile)
	color.a = 0
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, 0.5, 0)
	eapi.SetPos(tile, vector.Scale(eapi.GetPos(tile), 2))
	eapi.SetSize(tile, vector.Scale(eapi.GetSize(tile), 2))
end

local function JetPackText()
	local text = "Jetpack"
	local body = eapi.NewBody(gameWorld, vector.null)
	util.Map(FadeOut, util.BigTextCenter(text, body, 0))
	local function Jitter()
		eapi.SetPos(body, vector.Rnd(vector.null, 8))
		eapi.AddTimer(body, 0.01, Jitter)
	end
	Jitter()
	util.DelayedDestroy(body, 0.5)
end

local function JetPack()
	local black = { r = 0.0, g = 0.0, b = 0.0, a = 0.75 }
	local invisible = { r = 0.0, g = 0.0, b = 0.0, a = 0.0 }
	eapi.PlaySound(gameWorld, "sound/charge.ogg", 0, 1, 1)
	local size = { x = 1000, y = 600 }
	local pos = { x = -500, y = -300 }
	local screen = eapi.NewTile(staticBody, pos, size, util.white, 100)
	eapi.SetColor(screen, invisible)
	eapi.AnimateColor(screen, eapi.ANIM_CLAMP, black, 1, 0)
	local starDistance = { x = 470, y = 0 }
	local rainbow = explode.rainbow
	local offset = { x = -16, y = -16 }
	local size = { x = 32, y = 32 }
	local function PutStar(pos, time)
		local body = eapi.NewBody(gameWorld, pos)
		local tile = eapi.NewTile(body, offset, size, util.twinkle, 101)
		local index = 1 + 1.5 * (1 - time) * (#rainbow - 1)
		local color = rainbow[math.floor(math.min(index, #rainbow))]
		color.a = 0.0
		eapi.SetColor(tile, color)
		color.a = 0.5
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, time, 0)
		explode.SetRandomAngle(tile)
		local variation = 0.8 + 0.2 * math.random()
		local vel = vector.Scale(pos, variation)
		eapi.SetAcc(body, vector.Scale(vel, 2))
		eapi.SetVel(body, vector.Scale(vel, -2))
		local function Reverse()
			eapi.SetVel(body, vector.Scale(vel, 4))
		end
		eapi.AddTimer(body, time, Reverse)
		util.DelayedDestroy(body, time + 0.5)
	end
	local time = 1.0
	local function RandomStar()
		for i = 1, 10, 1 do
			local angle = 360 * math.random()
			local pos = vector.Rotate(starDistance, angle)
			PutStar(pos, time)
		end
		time = time - 0.05		
		if time > 0 then
			eapi.AddTimer(staticBody, 0.05, RandomStar)
		end
	end
	RandomStar()
	local function Release()
		eapi.AnimateColor(screen, eapi.ANIM_CLAMP, invisible, 0.5, 0)
		eapi.PlaySound(gameWorld, "sound/beat.ogg")
		player.Blast()
		JetPackText()
	end
	eapi.AddTimer(staticBody, 1.0, Release)
	flow.StopSwirl()
end

local function WallsWithHoles()
	for i = 64, 240, 32 do
		bomb.ThreeWayMine({ x = 500, y =  i })
		bomb.ThreeWayMine({ x = 500, y = -i })
	end
	timing.Schedule(0.5)
end

local function HerdTheMines()
	for y = -240, 240, 80 do
		local pos = { x = 432, y = y }
		local vel = vector.Sub(eapi.GetPos(player.obj.body), pos)
		bomb.ThreeWayMine(pos, vector.Normalize(vel, 400))
	end
	timing.Schedule(0.6)
end

local function DiagonalTunnels()
	local offset = 0
	return function()
		for i = -240, 240, 128 do
			bomb.ThreeWayMine({ x = 500, y = offset + i })
		end
		if offset > 96 then 
			offset = 0
			timing.Schedule(0.70)
		else
			offset = offset + 16
			timing.Schedule(0.10)
		end
	end
end

local function Fibonacci()
	local offset = 0
	local base = { x = 24, y = 0 }
	return function()
		local pos = { x = 500, y = offset - 240 }
		local angle = 360 * math.random()
		for i = 0, 359, 72 do
			local posOffset = vector.Rotate(base, angle + i)
			bomb.ThreeWayMine(vector.Add(pos, posOffset))
		end
		offset = (offset + (util.golden * 480)) % 480
		timing.Schedule(0.25)
	end
end

local function SineTunnel()
	local flip = 0
	local progress = 0.0
	local function Bar(pos, step)
		while math.abs(pos.y) < 250 do
			bomb.ThreeWayMine(pos)
			pos.y = pos.y + step
			if flip > 0 then break end
		end
	end
	return function()
		local y = 70 * math.sin(progress)
		Bar({ x = 500, y = y + 100 }, 40)
		Bar({ x = 500, y = y - 100 }, -40)
		progress = progress + 0.5
		timing.Schedule(0.1)
		flip = (flip + 1) % 3
	end
end

local function RaysOfDestruction()
	local spread = 20
	local origin = { x = 632, y = 0 }
	local posOffset = { x = -200, y = 0 }
	local baseVel = { x = -400, y = 0 }
	return function()
		for angle = -spread, spread, 10 do
			for j = 200, 120, -32 do
				local offset = vector.Normalize(posOffset, j)
				local pos = vector.Rotate(offset, angle)
				local vel = vector.Rotate(baseVel, angle)
				bomb.ThreeWayMine(vector.Add(origin, pos), vel)
			end
		end
		spread = 45 - spread
		timing.Schedule(0.5)
	end
end

local function DeadlyOscilators()
	local pos = { { x = 432, y = 100 }, { x = 432, y = -100 } }
	local aim = { x = -100, y = 0 }
	local vel = { }
	local step = 50
	local index = 1
	return function()
		vel[index] = vector.Sub(aim, pos[index])
		vel[index] = vector.Rotate(vel[index], 10 * (2 * index - 3))
		vel[index] = vector.Normalize(vel[index], 400)
		bomb.ThreeWayMine(pos[index], vel[index])
		aim.y = aim.y + step
		if math.abs(aim.y) > 200 then step = -step end
		timing.Schedule(0.15)
		index = 3 - index
	end
end

local function KillerBoxes()
	local function Box(x, y)
		for i = 0, 96, 32 do
			bomb.ThreeWayMine({ x = x + i, y = y - 48 })
			bomb.ThreeWayMine({ x = x + i, y = y + 48 })
		end
		for i = -16, 16, 32 do
			bomb.ThreeWayMine({ x = x, y = y - i })
			bomb.ThreeWayMine({ x = x + 96, y = y + i })
		end
	end
	local y = 0
	return function()
		Box(432, y - 128)
		y = (y + 128) % 384
		timing.Schedule(y == 0 and 0.2 or 0.6)
	end
end

local function MeshOfDoom()
	local step = 9
	local count = 10
	local height = 256
	local vel = { x = -400, y = 0 }
	return function()
		local angle = 5
		for i = 1, 4, 1 do
			local pos1 = { x = 432, y = height - i * 64 }
			bomb.ThreeWayMine(pos1, vector.Rotate(vel, angle))
			local pos2 = { x = 432, y = -height + i * 64 }
			bomb.ThreeWayMine(pos2, vector.Rotate(vel, -angle))
			angle = angle + step
		end
		count = count - 1
		if count <= 0 then
			timing.Schedule(0.5)
			height = 448 - height
			count = 10
		else
			timing.Schedule(0.1)
		end
	end
end

local function PrintBig(pos, text)
	return util.PrintOrange(pos, text, 400, nil, nil, util.bigFontset)
end

local function BangText(text, yOffset, volume)
	return function()
		eapi.PlaySound(gameWorld, "sound/beat.ogg", 0, volume)
		local pos = util.TextCenter(text, util.bigFontset)
		pos = vector.Offset(pos, 0, yOffset or 0)
		for i = pos.x, -pos.x, 32 do
			local puffPos = { x = i, y = pos.y + 32 }
			explode.TextBurst(puffPos, 399)
		end
		return PrintBig(pos, text)
	end
end

local heartColor = { }
heartColor[-1] = { r = 0.894, g = 0.404, b = 0.666, a = 0.8 }
heartColor[1] = { r = 0.941, g = 0.712, b = 0.778, a = 0.8 }
local srcSize = { x = 2, y = 2 }
local srcPos = { x = -1, y = -1 }
local dstSize = { x = 2048, y = 2048 }
local dstPos = { x = -1024, y = -1024 }
local heartTTL = 1
local heartZ = 100
local flip = 1

local function AnimateHearts()
	local body = eapi.NewBody(gameWorld, vector.null)
	local tile = eapi.NewTile(body, srcPos, srcSize, util.heart, heartZ)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, heartTTL, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, heartTTL, 0)
	eapi.AddTimer(staticBody, 0.05, AnimateHearts)
	eapi.SetColor(tile, heartColor[flip])
	util.DelayedDestroy(body, heartTTL)
	heartZ = heartZ + 0.0001
	flip = -flip
end

local function ShowText()
	util.DoEventsRelative(
		{ {  1.0, flow.HideBg },
		  {  0.0, BangText("Pony", 100, 0.25) },
		  {  0.5, BangText("+", 45, 0.25) },
		  {  0.5, BangText("Jetpack", 0, 0.25) },
		  {  0.5, BangText("=", -55, 0.25) },
		  {  1.0, BangText("Spaceship", -100, 1.0) }, })
end


local function MeetPony()
	local obj = player.obj
	player.DisableInput()
	eapi.SetAcc(obj.body, vector.null)
	local pos = eapi.GetPos(obj.body)
	eapi.SetVel(obj.body, vector.Sub(vector.null, pos))

	local size = { x = 125, y = 125 }
	local offset = { x = -64, y = -64 }
	local body = eapi.NewBody(gameWorld, { x = 464, y = 0 })
	local tile = eapi.NewTile(body, offset, nil, util.pony, -99.22)
	local shadow = eapi.NewTile(body, offset, size, util.pony, -99.219)
	eapi.SetColor(tile, { r = 0.53, g = 0.78, b = 0.91, a = 1.0 })
	eapi.SetColor(shadow, { r = 0, g = 0, b = 0, a = 0.2 })
	util.AnimateRotation(shadow, 32)
	util.AnimateRotation(tile, 32)
		
	eapi.SetVel(body, { x = -464, y = 0 })

	local function Reunite()
		eapi.FadeMusic(0.5)
		eapi.PlaySound(gameWorld, "sound/success.ogg")
		eapi.SetVel(obj.body, vector.null)
		eapi.SetVel(body, vector.null)
		AnimateHearts()
		ShowText()
	end
	eapi.AddTimer(staticBody, 1, Reunite)	
end

local function ToThePifPaf()
	timing.EndLevel(2)
	player.Freeze()
	util.Goto("pif-paf")
end

local patternList = {
	MinePattern({ 1.000 }),
	MinePattern({ 0.075, 0.075, 0.850, }),
	MinePattern({ 0.350, 0.075, 0.075, 1.200 }),
	MinePattern({ 0.075, 0.350, 0.075, 0.200, 0.075, 0.900 }),
	MinePattern({ 0.075, 0.075, 0.075, 0.075, 0.075, 0.400 }),
	MinePattern({ 0.075, 0.350, 0.800, 0.075, 0.075, 0.500}),
	MinePattern({ 0.380, 0.380, 0.380, 0.190, 0.190, }),
	MinePattern({ 0.075, 0.350, 0.600, 0.075, 0.500, 0.400, 0.350 }),
	timing.Delay(1.5),
	timing.Immediate(JetPack),
	timing.Delay(1.5),
	SineTunnel(),
	WallsWithHoles,
	DiagonalTunnels(),
	Fibonacci(),
	KillerBoxes(),
	RaysOfDestruction(),
	HerdTheMines,
	DeadlyOscilators(),
	MeshOfDoom(),
	timing.Delay(1.0),
	timing.Immediate(MeetPony),
	timing.Delay(7.0),
	ToThePifPaf,
}

timing.InsertDelays(patternList, 1.0)

TuneIn()
flow.Swirl()
flow.Start()
util.Delay(staticBody, 2, player.Create, timing.Start)
actor.Cage("Reaper", 1.1, 0.6, 0.55, 1.0)
timing.Progress(2)
