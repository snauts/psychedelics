local life = 0.5

local rainbow = {
	{ r = 1.00, g = 0.00, b = 0.00, a = 1.0 },
	{ r = 1.00, g = 0.50, b = 0.00, a = 1.0 },
	{ r = 1.00, g = 1.00, b = 0.00, a = 1.0 },
	{ r = 0.00, g = 1.00, b = 0.00, a = 1.0 },
	{ r = 0.00, g = 1.00, b = 1.00, a = 1.0 },
	{ r = 0.00, g = 0.00, b = 1.00, a = 1.0 },
	{ r = 0.40, g = 0.10, b = 0.20, a = 1.0 },
}

local function SetRandomColor(tile, color)
	color.a = 0.5
	eapi.SetColor(tile, color)
	color.a = 0.0
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, life, 0)
end

local function SetRandomAngle(tile)
	local speed = 0.25 + 0.25 * math.random()
	if math.random() > 0.5 then speed = -speed end
	util.AnimateRotation(tile, speed, 360 * math.random())
end

local function EmitParticle(pos, acc, scale, z, color, angle,
			    srcPos, srcSize, dstPos, dstSize)
	local variation = (0.25 + 0.75 * math.random())
	local speed = 256.0 * (0.1 + 0.9 * scale) * variation
	local baseVel = vector.Normalize(acc, speed)
	local body = eapi.NewBody(gameWorld, pos)
	local vel = vector.Rotate(baseVel, angle)
	local tile = eapi.NewTile(body, srcPos, srcSize, util.twinkle, z)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, dstPos, life, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, dstSize, life, 0)
	util.DelayedDestroy(body, life)
	eapi.SetAcc(body, acc)
	eapi.SetVel(body, vel)
	SetRandomColor(tile, color)
	SetRandomAngle(tile)
	return body
end

local size = { x = 8 , y = 8 }
local offset = { x = -4, y = -4 }

local function Puff(pos, scale, z)
	local acc = vector.Scale(pos, 2)
	scale = scale or math.min(256.0, vector.Length(pos)) / 256.0
	local srcPos = vector.Scale(offset, 1 + scale)
	local srcSize = vector.Scale(size, 1 + scale)
	local dstPos = vector.Scale(srcPos, 2)
	local dstSize = vector.Scale(srcSize, 2)
	local count = math.floor(5 + 10 * scale)
	for i = 1, count, 1 do
		local angle = 360 * math.random()
		local color = rainbow[math.random(1, #rainbow)]
		EmitParticle(pos, acc, scale, z or 20, color, angle,
			     srcPos, srcSize, dstPos, dstSize)
	end
end

local srcPos = { x = -4, y = -4 }
local srcSize = { x = 8, y = 8 }
local dstPos = { x = -16, y = -16 }
local dstSize = { x = 32, y = 32 }

local burstColors = {
	{ r = 1.0, g = 1.0, b = 0.0 },
	{ r = 1.0, g = 0.8, b = 0.0 },
	{ r = 1.0, g = 0.6, b = 0.0 },
}

local function Burst(pos, acc, width)
	for i = 1, 10, 1 do
		local angle = math.random(-width, width)
		local color = burstColors[math.random(1, #burstColors)]
		EmitParticle(pos, acc, 0.7, 5, color, angle,
			     srcPos, srcSize, dstPos, dstSize)
	end
end

local lastMineBurst = 0
local function GetBurstCount()
	local now = eapi.GetTime(gameWorld)
	local diff = now - lastMineBurst
	lastMineBurst = now
	local count = 5 + 10 * 10 * math.min(diff, 0.1)
	return count
end

local function MineBurst(pos, acc, z, velAdjust)
	acc = acc or { x = 0, y = 200 }
	local burstCount = GetBurstCount()
	for i = 1, burstCount, 1 do
		local angle = math.random(-90, 90)
		local color = rainbow[math.random(1, #rainbow)]
		local body = EmitParticle(pos, acc, 1, z, color, angle,
					  srcPos, srcSize, dstPos, dstSize)
		local vel = eapi.GetVel(body)
		vel.x = vel.x - velAdjust
		eapi.SetVel(body, vel)
	end
end

local function TextBurst(pos, z)
	local acc = { x = 0, y = 1 }
	for i = 1, 25, 1 do
		local angle = 360 * math.random()
		local color = rainbow[math.random(1, #rainbow)]
		local body = EmitParticle(pos, acc, 0.5, z, color, angle,
					  srcPos, srcSize, dstPos, dstSize)
		local vel = eapi.GetVel(body)
	end
end

explode = {
	Puff = Puff,
	Burst = Burst,
	rainbow = rainbow,
	MineBurst = MineBurst,
	TextBurst = TextBurst,
	burstColors = burstColors,
	EmitParticle = EmitParticle,
	SetRandomAngle = SetRandomAngle,
}
return explode
