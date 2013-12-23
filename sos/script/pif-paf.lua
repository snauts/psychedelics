dofile("script/pif-paf-player.lua")
dofile("script/ribbons.lua")
dofile("script/explode.lua")
dofile("script/timing.lua")
dofile("script/space.lua")
dofile("script/bomb.lua")

local testCardImg = actor.LoadSprite("image/test-card.png", { 800, 480 })

local function TestCard()
	local card = actor.FillScreen(testCardImg, 1000)

	local function Destroy()
		eapi.Destroy(card)
	end
	
	local function Fade()
		eapi.AnimateColor(card, eapi.ANIM_CLAMP, util.invisible, 2, 0)
		eapi.AddTimer(staticBody, 2, Destroy)
	end
	
	eapi.AddTimer(staticBody, 3, Fade)
	eapi.PlaySound(gameWorld, "sound/tone.ogg", 0, 0.5)
end

local function Aimer()
	local x = 0	
	return function()
		local pos = { x = -400 + x * 800, y = 272 }
		local vel = vector.Sub(actor.GetPos(player.obj), pos)
		bomb.SpaceMine(pos, vector.Normalize(vel, 400))
		x = (x + util.golden) % 1
		timing.Schedule(0.2)
	end
end

local function Crossed()
	local aim = nil
	local counter = 0
	local function Emit(x, angle)
		local pos = { x = x, y = 272 }
		local vel = vector.Rotate(vector.Sub(aim, pos), angle)
		bomb.SpaceMine(pos, vector.Normalize(vel, 400))
	end
	return function()
		if counter == 0 then aim = actor.GetPos(player.obj) end
		for x = -300, 300, 300 do
			for angle = -60, 60, 30 do
				Emit(x, angle)
			end
		end
		if counter < 5 then
			timing.Schedule(0.1)
			counter = counter + 1
		else
			timing.Schedule(0.5)
			counter = 0
		end
	end
end

local function Phyllotaxis()
	local angle = 0
	local pos = { x = 0, y = 368 }
	local baseVel = { x = -400, y = 0 }
	return function()
		angle = (angle + 180 * util.golden) % 180
		local vel = vector.Rotate(baseVel, angle)
		bomb.SpaceMine(pos, vel)
		timing.Schedule(0.03)
	end
end

local function Darts()
	local flip = 1
	local size = 48
	local step = 24
	local baseVel = { x = 0, y = -200 }
	local function Dart(pos, dir)
		for y = -dir * size, dir * size, dir * step do			
			local x = y  + dir * size
			bomb.SpaceMine(vector.Offset(pos, x, y), baseVel)
			bomb.SpaceMine(vector.Offset(pos, -x, y), baseVel)
		end
	end
	return function()
		for x = -500, 500, size * 6 do 
			Dart({ x = x + 1.5 * flip * size, y = 320 }, flip)
		end
		timing.Schedule(flip < 0 and 0.6 or 0.9)
		flip = -flip
	end
end

local function BadBomb(pos, vel)
	return math.abs(pos.x) > 350 and util.Sign(pos.x) == util.Sign(vel.x)
end

local function RemoveAfter(obj, time)
	eapi.AddTimer(obj.body, time, function() actor.Delete(obj) end)
end

local function Mesh()
	local step = 5
	local offset = 0
	local amplitude = 80
	return function()
		for dir = -1, 1, 2 do
			for i = -600, 600, 120 do
				local slide = math.abs(offset) - 0.5 * amplitude
				local pos = { x = i + slide, y = 322 + offset }
				local vel = { x = dir * 150, y = -300 }
				if not BadBomb(pos, vel) then
					local obj = bomb.SpaceMine(pos, vel)
					RemoveAfter(obj, 2.2)
				end
			end
		end
		timing.Schedule(0.1)
		offset = offset + step
		if math.abs(offset) > amplitude then
			step = -step
		end
	end
end

local function Checkers()
	local flip = true
	local counter = 0
	local function Test()
		local test = (counter % 12 > 5)
		counter = counter + 1
		return (test and flip) or not (test or flip)
	end
	local dir = 8
	local function CheckerMine(pos, vel)
		if Test() then 
			bomb.SpaceMine(pos, vel)
			dir = -dir
		end
	end
	return function()
		counter = 0
		for i = -430, 430, 24 do		
			CheckerMine({ x = i, y = 272 + dir }, 
				    { x = 0, y = -200 })
		end
		counter = 0
		for i = -240, 240, 24 do			
			local side = flip and 1 or -1
			CheckerMine({ x = side * (432 + dir), y = i }, 
				    { x = -200 * side, y = 0 })
		end
		flip = not flip
		timing.Schedule(1.0)
	end
end

local broom = nil

local function StartBroom()
	local obj = { class = "Broom",
		      pos = { x = 0, y = 200 },
		      velocity = { x = 200, y = 0 },		      
		      bb = { l = -96, r = 96, b = -16, t = 16 } }
	broom = actor.Create(obj)
	local function Reverse()
		broom.velocity.x = -broom.velocity.x
		eapi.SetVel(broom.body, broom.velocity)
		eapi.AddTimer(broom.body, 2, Reverse)
	end
	eapi.AddTimer(broom.body, 1, Reverse)
end

local function StopBroom()
	actor.Delete(broom)
end

local function TouchBroom(pShape, mShape)
	local obj = actor.store[mShape]
	if not obj.swept then
		local mobPos = eapi.GetPos(obj.body)
		local broomPos = eapi.GetPos(broom.body)
		local dir = util.Sign(mobPos.x - broomPos.x)
		eapi.SetVel(obj.body, { x = 300 * dir, y = -400 })
		eapi.SetAcc(obj.body, { x = -600 * dir, y = 0 })
		obj.swept = true
	end
end

actor.SimpleCollide("Broom", "Mob", TouchBroom)

local function Sweeper()
	local progress = 0
	local baseVel = { x = 0, y = -400 }
	return function()
		local pos = { x = progress * 800 - 400, y = 272 }
		bomb.SpaceMine(pos, baseVel)
		progress = (progress + util.golden) % 1
		timing.Schedule(0.01)
	end
end

local function Splode()
	local progress = 0
	local baseVel = { x = 0, y = -200 }
	local function BlowingMine(pos, offset)
		local obj = bomb.SpaceMine(vector.Add(pos, offset), baseVel)
		local function Blow()
			if not obj.destroyed then
				local vel = vector.Normalize(offset, 300)
				vel = vector.Add(baseVel, vel)
				eapi.SetVel(obj.body, vel)
			end
		end
		eapi.AddTimer(obj.body, 1.0, Blow)
	end
	local function Bomb(pos)
		for i = 0, 359, 45 do
			local angle = 360 * progress + i
			local offset = vector.Rotate({ x = 32, y = 0 }, angle)
			BlowingMine(pos, offset)
		end
	end
	return function()
		Bomb({ x = progress * 800 - 400, y = 320 })
		progress = (progress + util.golden) % 1
		timing.Schedule(0.5)
	end
end

local function Curtain()
	local step = 2
	local progress = 0
	local acc = { x = 0, y = 0 }
	local baseVel = { x = 0, y = -800 }
	return function()
		for i = 0, 40, 40 do
			local x = progress * 800 - 400
			local pos = { x = x - acc.x * 0.1, y = 272 + i }
			local vel = vector.Rotate(baseVel, 0.05 * pos.x)
			local obj = bomb.SpaceMine(pos, vel)
			eapi.SetAcc(obj.body, acc)

			acc.x = acc.x + step
			if math.abs(acc.x) > 600 then step = -step end
		end
		progress = (progress + 0.1) % 1
		timing.Schedule(0.01)
	end
end

local function Pizza()
	local arm = { x = 466, y = 0 }
	local angle = 0
	local adjust = 0
	local step = 0.25
	return function()
		for i = 15, 175, 30 do
			local pos = vector.Rotate(arm, angle + i)
			local vel = vector.Normalize(pos, -800)			
			vel = vector.Rotate(vel, adjust)
			local acc = vector.Rotate(pos, -90)
			local obj = bomb.SpaceMine(pos, vel)
			eapi.SetAcc(obj.body, vector.Normalize(acc, 250))
		end
		if math.abs(adjust) > 5 then step = -step end
		adjust = adjust + step
		angle = angle + 2
		timing.Schedule(0.06)
	end
end

local function TestAngle(gamma, dir)
	local left  = (dir < 0 and gamma > 45 and gamma < 170)
	local right = (dir > 0 and gamma > 10 and gamma < 135)
	return (left or right)
end

local function Radials()
	local angle = 0
	local baseVel = { x = -250, y = 0 }
	local function EmitArc(x, dir)
		local pos = { x = x, y = 368 }
		for alpha = 0, 359, 30 do
			for beta = 0, 6, 3 do
				gamma = dir * (alpha + beta + angle)
				local vel = vector.Rotate(baseVel, gamma)
				if TestAngle(gamma % 360, dir) then
					bomb.SpaceMine(pos, vel)
				end
			end
		end
	end
	return function()
		for x = -300, 300, 600 do EmitArc(x, util.Sign(x)) end
		angle = (angle + util.fibonacci) % 360
		timing.Schedule(0.5)
	end
end

local function Pivot(pos, vel)
	local obj = { pos = pos,
		      velocity = vel,
		      class = "Garbage",
		      bb = actor.Square(8), }
	return actor.Create(obj)		      
end

local function Slicers()
	local dir = 1
	local delay = 0.35
	local progress = 0
	local interval = 2.0
	local sideSpeed = 200
	local baseVel = { x = 0, y = -200 }
	local function AddBomb(parent, dir, dx, dy)
		local vel = { x = -sideSpeed * dir, y = 0 }
		local pos = eapi.GetPos(parent.body)
		local pos = vector.Offset(pos, dx, dy)
		local child = bomb.SpaceMine(pos, vel)
		actor.Link(child, parent)
	end
	local function ColumnOfBombs(parent, dir, dx)
		for dy = 0, 48, 24 do
			AddBomb(parent, dir, dx, dy)
		end
	end
	local function EmitSlices(parent, dir)
		local function Emit()
			ColumnOfBombs(parent, dir, 0)
			eapi.AddTimer(parent.body, interval, Emit)
		end
		Emit()
	end
	return function()
		local parent = Pivot({ x = 432 * dir, y = 272 }, baseVel)
		local distance = progress * sideSpeed
		for dx = distance, 800, interval * sideSpeed do			
			ColumnOfBombs(parent, dir, -dir * dx)
		end
		local emitDelay = interval - progress
		util.Delay(parent.body, emitDelay, EmitSlices, parent, dir)
		progress = (progress + delay) % interval
		timing.Schedule(delay)
		dir = -dir
	end
end

local function AddChild(parent, speed, childPos)
	local child = bomb.SpaceMine(childPos, vector.null)
	actor.Link(child, parent)
	eapi.SetStepC(child.body, eapi.STEPFUNC_ROT, speed)		
end

local function Square(pos, speed)
	local vel = vector.Rotate({ x = 0, y = -400 }, 0.01 * pos.x)
	local parent = Pivot(pos, vel)
	for i = -48, 48, 32 do
		AddChild(parent, speed, { x = pos.x + i, y = pos.y - 48 })
		AddChild(parent, speed, { x = pos.x + i, y = pos.y + 48 })
	end
	for i = -16, 16, 32 do
		AddChild(parent, speed, { x = pos.x - 48, y = pos.y - i })
		AddChild(parent, speed, { x = pos.x + 48, y = pos.y + i })
	end
	
end

local function Esquarez()
	local flip = 1
	return function()
		for x = -450 + flip * 50, 450 - flip * 50, 200 do
			Square({ x = x, y = 372 }, 2 * flip)
		end
		flip = -flip
		timing.Schedule(0.55)
	end
end

local function OneTick(pos, speed, vel)
	local parent = Pivot(pos, vel)
	for i = 32, 64, 32 do
		for j = 0, 240, 120 do
			local offset = { x = i, y = 0 }
			offset = vector.Rotate(offset, j)
			offset = vector.Add(offset, pos)
			AddChild(parent, speed, offset)
		end
	end
end

local tickers = {
	{ pos = { x = 0, y = 372 }, offset = { x = 200, y = 0 } },
	{ pos = { x = 0, y = -372 }, offset = { x = -200, y = 0 } },
	{ pos = { x = 532, y = 0 }, offset = { x = 0, y = 200 } },
	{ pos = { x = -532, y = 0 }, offset = { x = 0, y = -200 } },
}

local function Ticks()
	local arm = { x = 0, y = -150 }
	return function()
		for i, value in pairs(tickers) do
			local pos = value.pos
			local aim = vector.Add(arm, value.offset)
			local vel = vector.Sub(aim, pos)
			OneTick(pos, 2, vector.Normalize(vel, 400))
		end
		timing.Schedule(0.3)
		arm = vector.Rotate(arm, 20)
	end
end

local function FallingArc(pos, speed, angle)
	local base = { x = 68, y = 0 }
	local parent = Pivot(pos, { x = 0, y = -200 })
	for i = -105, 105, 30 do
		local offset = vector.Rotate(base, 180 - angle + i)
		AddChild(parent, speed, vector.Add(pos, offset))
	end
	
end

local function Rings()
	local dir = 1
	local alpha = 180
	return function()
		for x = -320, 320, 160 do
			FallingArc({ x = x, y = 372 }, 4 * dir, alpha)
			alpha = 180 - alpha
			dir = -dir
		end
		timing.Schedule(0.75)
	end
end

local function Wigglers()
	local angle = 0
	local amplitude = 512
	local function Oscilator(obj)
		util.Delay(obj.body, 1.0, Oscilator, obj)
		eapi.SetAcc(obj.body, { x = amplitude * obj.dir, y = 0 })
		obj.dir = -obj.dir
	end
	local function Emit(pos, dir)
		local parent = Pivot(pos, { x = 0, y = -420 })
		local child = bomb.SpaceMine(pos, vector.null)
		actor.Link(child, parent)
		eapi.SetVel(child.body, { x = -0.5 * dir * amplitude, y = 0 })
		child.dir = dir
		Oscilator(child)
	end
	local dir = 1
	local step = 10
	local offset = 0
	return function()
		for i = -450, 450, 100 do
			Emit({ x = i + dir * offset, y = 360 }, dir)
			dir = -dir
		end
		if offset > 140 or offset < -70 then step = -step end
		offset = offset + step
		timing.Schedule(0.11)
	end
end

local function TheEnd()
	timing.EndLevel(3)
	util.Goto("end")
end

local fadeOut = 5.0
local function Fade()
	eapi.FadeMusic(fadeOut)
	local dark = { r = 0, g = 0, b = 0, a = 0 }
	local tile = actor.FillScreen(util.white, 1000, dark)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.Gray(0), fadeOut, 0)
end

local fragmentSize = 32
local ratSize = { x = 256, y = 192 }
local ratFragment = { fragmentSize, fragmentSize }
local ratImg = actor.LoadSprite("image/evil-rat.png", ratSize)
local ratFragmentImg = actor.LoadSprite("image/evil-rat.png", ratFragment)
local ratOffset = { x = -fragmentSize * 0.5, y = -fragmentSize * 0.5 }

local function RatFragment(pos, x, y, index)
	local vel = { x = x, y = y }
	local len = vector.Length(vel)
	vel = vector.Normalize(vel, 128 + len)
	local rotation = (math.random() - 0.5)
	local body = eapi.NewBody(gameWorld, vector.Offset(pos, x, y))
	local tile = eapi.NewTile(body, ratOffset, nil, ratFragmentImg, -1)
	eapi.SetVel(body, vector.Rotate(vel, math.random(-10, 10)))
	util.AnimateRotation(tile, rotation - 0.5 * util.Sign(rotation))
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 1, 0)
	eapi.SetAcc(body, vector.Scale(vel, 2))
	util.DelayedDestroy(body, 1.0)
	eapi.SetFrame(tile, index)
end

local rats = { }

local function RatExplode(num)
	local index = 0
	local ratW = 0.5 * ratSize.x 
	local ratH = 0.5 * ratSize.y
	local pos = eapi.GetPos(rats[num])
	eapi.Destroy(rats[num])
	eapi.PlaySound(gameWorld, "sound/beat.ogg")
	for y = ratH - fragmentSize / 2, -ratH, -fragmentSize do
		for x = -ratW + fragmentSize / 2, ratW, fragmentSize do
			RatFragment(pos, x, y, index)
			index = index + 1
		end
	end
end

local function Rat(num, xOffset, slowDownDelay)
	local offset = vector.Scale(ratSize, -0.5)
	local body = eapi.NewBody(gameWorld, { x = xOffset, y = 432 })
	local tile = eapi.NewTile(body, offset, ratSize, ratImg, -1)
	eapi.SetVel(body, { x = 0, y = -200 })
	local function Stop()
		eapi.SetVel(body, vector.null)
		eapi.SetAcc(body, vector.null)
	end
	local function SlowDown()
		eapi.SetAcc(body, { x = 0, y = 400 })
		eapi.AddTimer(body, 0.5, Stop)
	end
	eapi.AddTimer(body, slowDownDelay, SlowDown)
	rats[num] = body
end

local evijaImg = actor.LoadSprite("image/evija.png", { 64, 64 })

local function Flux(sprite, dir, speed, Colorize, Scaling, count)
	count = count or 100
	if count == 0 then return end
	local scale = Scaling()
	local var = math.random()
	local angle = dir * (30 * var - 15)
	local vel = { x = dir * 350, y = 0 }
	local pos = { x = -dir * 432, y = 75 + var * 50  }
	local body = eapi.NewBody(gameWorld, pos)
	local size = vector.Scale({ x = 64, y = 64 }, scale)
	local offset = vector.Scale({ x = -32, y = -32 }, scale)
	local tile = eapi.NewTile(body, offset, size, sprite, 1)
	local function Emit()
		Flux(sprite, dir, speed, Colorize, Scaling, count - 1)
	end
	eapi.SetVel(body, vector.Rotate(vel, angle))
	eapi.SetAcc(body, { x = 0, y = -400 })
	eapi.AddTimer(staticBody, 0.01, Emit)
	util.AnimateRotation(tile, speed)
	util.DelayedDestroy(body, 2)
	Colorize(tile)
end

local function Shine(intensity)
	local size = { x = 1024, y = 1024 }
	local offset = { x = -512, y = -512 }
	local color = { r = 1.0, g = 1.0, b = 1.0, a = intensity }
	local body = eapi.NewBody(gameWorld, { x = 0, y = -300 })
	eapi.PlaySound(gameWorld, "sound/success.ogg")
	for i = -9, 9, 6 do
		local tile = eapi.NewTile(body, offset, size, util.shine, 10)
		util.AnimateRotation(tile, i)
		eapi.SetColor(tile, color)
	end	
end

local function ColorizeGirl(tile)
	eapi.SetColor(tile, util.Gray(0.8 + 0.2 * math.random()))
	eapi.Animate(tile, eapi.ANIM_LOOP, 32, math.random())
end

local function GirlScaling()
	return 0.9 + 0.2 * math.random()
end

local function GirlFlux()
	util.Delay(staticBody, 1.5, Shine, 0.05)
	Flux(evijaImg, 1, -16, ColorizeGirl, GirlScaling)
	util.Delay(staticBody, 0.6, RatExplode, 2)
end

local function ColorizeHeart(tile)
	local var = 0.25 + 0.5 * math.random()
	eapi.SetColor(tile, { r = 1.0, g = var, b = var })
end

local function HeartScaling()
	return 0.25 + 0.5 * math.random()
end

local function HeartFlux()
	util.Delay(staticBody, 1.5, Shine, 0.1)
	Flux(util.heart, -1, -2, ColorizeHeart, HeartScaling)
	util.Delay(staticBody, 0.6, RatExplode, 1)
end

local function ExplodeMiddleRat()
	RatExplode(3)
	util.Delay(staticBody, 0.9, Shine, 0.1)
end

local function RainbowColor(var)
	local lower = var * (#explode.rainbow - 1)
	local index = math.floor(1 + lower)
	local color1 = explode.rainbow[index]
	local color2 = explode.rainbow[index + 1]
	return util.Mix(color1, color2, lower % 1)
end

local srcSize = { x = 40, y = 40 }
local srcPos = { x = -20, y = -20 }
local dstSize = { x = 64, y = 64 }
local dstPos = { x = -32, y = -32 }
local rainbowForce = 800
local rainbowAngle = 0
local rainbowStep = 10

local function RainbowBlock(var)
	local ttl = 1.7
	local half = var - 0.5
	local dir = util.Sign(half)
	local pos = { x = -0.2 * rainbowForce + 300 * var, y = -256 }
	local body = eapi.NewBody(gameWorld, pos)
	local gravity = -800 - 200 * math.pow(math.abs(2 * half), 2)
	local tile = eapi.NewTile(body, srcPos, srcSize, util.white, 5)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, ttl, 0)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, ttl, 0)
	eapi.SetVel(body, { x = 250 * (var - 0.5), y = rainbowForce })
	util.AnimateRotation(tile, -4 * dir + half, dir * rainbowAngle)
	eapi.SetAcc(body, { x = 0, y = gravity })
	util.DelayedDestroy(body, ttl)

	local color = RainbowColor(var)	
	eapi.SetColor(tile, util.SetColorAlpha(color, 1))
	local invisible = util.SetColorAlpha(color, 0)
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, invisible, ttl, 0)
end

local function Rainbow()
	for i = 0, 0.99999, 0.07 do RainbowBlock(i) end
	eapi.AddTimer(staticBody, 0.045, Rainbow)
	rainbowAngle = (rainbowAngle + 10) % 360
	rainbowForce = rainbowForce - rainbowStep
	if rainbowForce > 800 or rainbowForce < 700 then 
		rainbowStep = -rainbowStep
	end
end

timing.patternList = {
	Aimer(),
	timing.Delay(0.5),	
	Phyllotaxis(),
	timing.Delay(1.0),	
	timing.Immediate(StartBroom),
	Sweeper(),
	timing.Delay(0.5),	
	timing.Immediate(StopBroom),
	Splode(),
	timing.Delay(3.0),	
	Slicers(),
	timing.Delay(3.5),	
	Ticks(),
	timing.Delay(1.5),	
	Curtain(),
	timing.Delay(0.7),	
	Crossed(),
	timing.Delay(1.5),	
	Rings(),
	timing.Delay(4.0),	
	Pizza(),
	timing.Delay(0.8),	
	Radials(),
	timing.Delay(2.0),	
	Wigglers(),
	timing.Delay(1.0),	
	Checkers(),
	timing.Delay(4.0),	
	Esquarez(),
	timing.Delay(0.5),	
	Darts(),
	timing.Delay(2.0),	
	Mesh(),
	timing.Immediate(util.Closure(eapi.SetMusicVolume, 0.2, 1.5)),
	timing.Delay(1.5),
	timing.Immediate(util.Closure(Rat, 1, 200, 2.0)),
	timing.Delay(0.5),	
	timing.Immediate(util.Closure(Rat, 2, -200, 1.8)),
	timing.Delay(0.5),	
	timing.Immediate(util.Closure(Rat, 3, -32, 1.4)),
	timing.Delay(2.0),
	timing.Immediate(GirlFlux),
	timing.Delay(3.0),
	timing.Immediate(HeartFlux),
	timing.Delay(3.0),		
	timing.Immediate(Rainbow),
	timing.Delay(0.75),		
	timing.Immediate(ExplodeMiddleRat),
	timing.Delay(3.0),		
	timing.Immediate(Fade),
	timing.Delay(fadeOut + 2),	
	TheEnd,
}

TestCard()
space.Background()
util.Delay(staticBody, 3, player.Create, timing.Start)
actor.Cage("Reaper", 1.1, 1.0)
timing.Progress(3)
