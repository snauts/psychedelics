local flowImg = actor.LoadSprite("image/flow.png", { 256, 128 })

local function GetColor(z)
	local dir = util.Sign(z)
	z = math.abs(z)
	if dir > 0 then
		return { r = 0.0, g = 0.8 * z, b = 0.6 + 0.4 * z, a = 0.5 }
	else
		return { r = 1.0 * z, g = 0.2 * z, b = 0.6 - 0.2 * z, a = 0.5 }
	end
end

local bgTiles = { }

local function HideBg()
	util.Map(eapi.Destroy, bgTiles)
	bgTiles = { }
end

local function Start()
	for z = -1.00, 1.00, 0.1 do
		local scale = 0.8 + 0.4 * math.abs(z)
		local fps = 32 + math.floor(32 * math.abs(z))
		local size = vector.Scale({ x = 1024, y = 128}, scale)
		local offset = vector.Scale({ x = -512, y = -64 }, scale)
		offset = vector.Offset(offset, 0, z * 240)
		local tile = eapi.NewTile(staticBody, offset, size,
					  flowImg, math.abs(z) - 100)		
		eapi.Animate(tile, eapi.ANIM_LOOP, fps, math.random())
		eapi.SetColor(tile, GetColor(z))
		bgTiles[tile] = tile
	end
end

local function Background(body, sprite, color, z, flip, height, offset)
	local size = { x = 1000, y = height }
	local offset = { x = -500, y = offset }
	local tile = eapi.NewTile(body, offset, size, sprite, z)
	eapi.SetColor(tile, color)
	eapi.FlipY(tile, flip)
	bgTiles[tile] = tile
	return tile
end

local color1 = { r = 0.0, g = 0.0, b = 0.4 }
Background(staticBody, util.white, color1, -1020, false, 600, -300)
local color2 = { r = 0.8, g = 0.2, b = 0.3 }
Background(staticBody, util.gradient, color2, -1010, true, 300, -300)
local color3 = { r = 0.0, g = 0.6, b = 0.8 }
Background(staticBody, util.gradient, color3, -1010, false, 300, 0)

local swirlImg = actor.LoadSprite("image/swirl.png", { 128, 64 })

local swirlTiles = { }

local function Swirl()
	local size = { x = 400, y = 96 }
	for i = -400, 400, 200 do
		local pos = { x = i - 200, y = -192 }
		local z = -99.22 + i * 0.00001
		local tile = eapi.NewTile(staticBody, pos, size, swirlImg, z)
		eapi.Animate(tile, eapi.ANIM_LOOP, 32, i * 0.001)
		swirlTiles[tile] = tile
	end
end

local function StopSwirl()
	local function DestroySwirls()
		util.Map(eapi.Destroy, swirlTiles)
		swirlTiles = { }
	end
	eapi.AddTimer(staticBody, 1.1, DestroySwirls)
	local function FadeSwirl(tile)
		eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 1, 0)
	end
	util.Map(FadeSwirl, swirlTiles)
end

local srcPos = { x = -4, y = -4 }
local srcSize = { x = 8, y = 8 }
local dstPos = { x = -16, y = -16 }
local dstSize = { x = 32, y = 32 }

local lastEmit = 0

local function EmitDust(acc, angleVar, scale)
	local burstColors = explode.burstColors
	local angle = math.random(-angleVar, angleVar)
	local color = burstColors[math.random(1, #burstColors)]
	local pos = eapi.GetPos(player.obj.body)
	pos.x = pos.x + math.random(-10, 10) - 10
	pos.y = pos.y + math.random(-5, 5) - 20
	local z = -99.205 + 0.01 * math.random()
	return explode.EmitParticle(pos, acc, scale or 0.7, z, color, angle,
				    srcPos, srcSize, dstPos, dstSize)		
end

local feetDustAcc = { x = -100, y = 50 }
local jetpackDustAcc = { x = -100, y = -10 }

local function JetpackDust()
	for i = 1, 5, 1 do EmitDust(jetpackDustAcc, 10, 1.0) end
end

local function Dust()
	if player.obj.onGround then EmitDust(feetDustAcc, 20) end
	if player.obj.flying then JetpackDust() end
	eapi.AddTimer(staticBody, 0.1, Dust)
end

local fallDustAcc = { x = 0, y = 100 }
local fallDustGravity = { x = -200, y = -250 }

local function Puff()
	eapi.PlaySound(gameWorld, "sound/leaves.ogg", 0, 0.5)
	for i = 1, 20, 1 do
		local body = EmitDust(fallDustAcc, 45)
		eapi.SetAcc(body, fallDustGravity)		
	end
end

flow = {
	JetpackDust = JetpackDust,
	StopSwirl = StopSwirl,
	HideBg = HideBg,
	Start = Start,
	Swirl = Swirl,
	Dust = Dust,
	Puff = Puff,
}
return flow
