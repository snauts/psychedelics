local cloudImg = actor.LoadSprite("image/cloud.png", { 128, 256 })

local animOffset = 0
local function CloudTile(xOffset, z)
	local size = { x = 128, y = 512 }
	size = vector.Scale(size, 1 + 2 * z)
	local pos = vector.Offset(vector.Scale(size, -0.5), xOffset, 0)
	local color = { r = 0.8 * z, g = 0.15 * z, b = 0.6 - 0.3 * z, a = 0.25 }
	local tile = eapi.NewTile(staticBody, pos, size, cloudImg, -100.1 + z)
	eapi.Animate(tile, eapi.ANIM_LOOP, 32, animOffset)
	animOffset = (animOffset + 0.5 + math.random()) % 3
	eapi.SetColor(tile, color)
	return tile
end

local function Clouds()
	for z = 0.0, 1.0, 0.5 do
		local width = 128 + z * 256
		for xOffset = -384, 384, 0.5 * width do
			CloudTile(xOffset, z)
		end
	end
end

local function Falling(z, len, ttl, sprite, CallBack)
	local pos = { x = math.random(-400 - len, 400 + len), y = 240 + len }
	local body = eapi.NewBody(gameWorld, pos)
	local size = { x = 2 * len, y = 2 * len }
	local offset = { x = -len, y = -len }
	local tile = eapi.NewTile(body, offset, size, sprite, -100 + z)
	eapi.SetVel(body, { x = 0, y = -(480 + 2 * len) / ttl })
	util.MaybeCall(CallBack, body, size, offset)
	util.DelayedDestroy(body, ttl)
	eapi.FlipY(tile, true)
	return tile
end

local starColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.1 }
local starDstColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.5 }

local function FallingStars()
	local z = math.random()
	local tile = Falling(z, 4 + 4 * z, 4 - 2 * z, util.twinkle)
	eapi.SetColor(tile, starColor)
	eapi.AnimateColor(tile, eapi.ANIM_REVERSE_LOOP, starDstColor, 0.05, z)
	explode.SetRandomAngle(tile)
end

local function Background()
	local function Start()
		FallingStars()
		eapi.AddTimer(staticBody, 0.1, Start)
	end
	Clouds()
	Start()
end

space = {
	Background = Background,
}
return space
