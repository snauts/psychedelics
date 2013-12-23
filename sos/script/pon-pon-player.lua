local evijaImg = actor.LoadSprite("image/evija.png", { 64, 64 })

local function DoJump(player)
	eapi.PlaySound(gameWorld, "sound/woosh.ogg")
	eapi.AddTimer(player.body, player.accDelay, player.Gravity)
	eapi.SetVel(player.body, player.vel)
	eapi.SetFrame(player.layer, 25)
	eapi.SetFrame(player.tile, 25)
	player.onGround = false
	player.jumpAgain = false
end

local function JumpFixup(player)
	if eapi.GetVel(player.body).y < -150 then
		player.jumpAgain = true
	end
end

local function Jump(player)
	return function(keyDown)
		if keyDown then
			if player.onGround then
				DoJump(player)
			else
				JumpFixup(player)
			end
		end
	end
end

local function RemoveText(player)
	return function(keyDown)
		if keyDown then
			local JumpFn = Jump(player)			
			input.Bind("Move", false, JumpFn)
			util.Map(eapi.Destroy, player.text)
			local displace = { x = 8, y = 8 }
			local color = { r = 0.5, g = 1.0, b = 0.0, a = 0.4 }
			actor.AddProgressCircle(player, color, displace)
			bomb.ResetTime()
			player.Launch()
			JumpFn(keyDown)
		end
	end
end

local function EnableInput(player)
	input.Bind("Move", false, RemoveText(player))
end

local tailChange = 0.12
local function AnimateTailColor(tile, color, index, maxIndex)
	color.a = 0.2 * (maxIndex - index) / maxIndex
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, color, tailChange, 0)
end

local function RunAnimation(obj)
	eapi.Animate(obj.tile, eapi.ANIM_LOOP, 32, 0)
	eapi.Animate(obj.layer, eapi.ANIM_LOOP, 32, 0)
end

local function HaltMotion(obj)
	eapi.SetVel(obj.body, vector.null)
	eapi.SetAcc(obj.body, vector.null)
end

local function StopSparkleSound(player)
	if player.sparkle then
		eapi.FadeSound(player.sparkle, 0.1)
		player.sparkle = nil
	end
end

local function PlayerVsBlock(pShape, sShape)
	local obj = player.obj
	RunAnimation(obj)
	HaltMotion(obj)
	eapi.SetPos(obj.body, obj.pos)
	obj.onGround = true
	flow.Puff()

	if obj.jumpAgain then DoJump(obj) end
end

actor.SimpleCollide("Player", "Block", PlayerVsBlock, nil, false)

local function Create(Launch)
	local obj = { z = -99.215,
		      fallTime = 0,
		      onGround = true,
		      sprite = evijaImg,
		      class = "Player",
		      accDelay = 0.1,
		      acc = { x = 0, y = -800 },
		      vel = { x = 0, y = 200 },
		      pos = { x = -100, y = -107 },
		      offset = { x = -32, y = -32 },
		      bb = { l = -8, r = 8, b = -16, t = 16 },
		      parentBody = eapi.NewBody(gameWorld, vector.null), }	
	local x = obj.pos.x
	obj = actor.Create(obj)
	local bb = { l = x - 16, r = x + 16, b = -140 - 96, t = -140 + 16 }
	obj.block = eapi.NewShape(staticBody, nil, bb, "Block")
	actor.MakeShape(obj, { l = 8, r = 20, b = 12, t = 24 })
	
	local z = obj.z + 0.00001
	local offset = { x = -32, y = -32 }
	local size = { x = 62, y = 62 }
	obj.layer = eapi.NewTile(obj.body, offset, size, obj.sprite, z)
	local color = { r = 0, g = 0, b = 0, a = 0.2 }
	eapi.SetColor(obj.layer, color)
	RunAnimation(obj)

	local text = "\"Space\" - Jump"
	ribbons.ShowHelpText(obj, text)

	local text = "Dedicated to my daughter Evija."
	local tiles = ribbons.CenterText(text, -228)
	obj.text = util.JoinTables(obj.text, tiles)
	
	obj.Launch = Launch
	player.obj = obj
	EnableInput(obj)
	flow.Dust()

	obj.Gravity = function()
		eapi.SetAcc(obj.body, obj.acc)
	end
end

local function StopFlying(player)
	eapi.SetAcc(player.body, player.acc)
	player.flying = false
	StopSparkleSound(player)
end

local function SparkleSound(player)
	player.sparkle = eapi.PlaySound(gameWorld, "sound/sparkle.ogg", -1)
end

local function Fly(player)
	return function(keyDown)
		if keyDown then
			SparkleSound(player)
			eapi.SetVel(player.body, player.vel)
			eapi.SetAcc(player.body, vector.null)
			player.flying = true
			flow.JetpackDust()
		else
			StopFlying(player)
		end
	end
end

local function PlayerVsKick(pShape, sShape)
	local obj = player.obj
	local pos = eapi.GetPos(obj.body)
	local dir = util.Sign(pos.y)
	eapi.SetVel(obj.body, { x = 0, y = -dir * 600 })
	explode.MineBurst(pos, { x = 0, y = -dir * 200 }, -99.2, 400)
	eapi.PlaySound(gameWorld, "sound/burst.ogg")
	bomb.ResetTime()
	StopFlying(obj)
end

actor.SimpleCollide("Player", "Kick", PlayerVsKick)

local function Blast()
	local obj = player.obj
	local x = obj.pos.x
	eapi.Destroy(obj.block)
	eapi.PlaySound(gameWorld, "sound/woosh.ogg")
	eapi.SetVel(obj.body, { x = 0, y = 600 })
	eapi.SetAcc(obj.body, { x = 0, y = -800 })
	input.Bind("Move", false, Fly(player.obj))
	obj.onGround = false
	RunAnimation(obj)
	for y = -300 - 32, 240 + 32, 540 + 64 do
		local bb = { l = x - 16, r = x + 16, b = y, t = y + 60  }
		obj.block = eapi.NewShape(staticBody, nil, bb, "Kick")
	end
end

local function DisableInput()
	input.Bind("Move")
end

local function Freeze()
	local obj = player.obj
	DisableInput()
	HaltMotion(obj)
	actor.DeleteShape(obj)
	StopSparkleSound(obj)
	eapi.FadeMusic(0.01)
end

player = {
	Blast = Blast,
	Freeze = Freeze,
	Create = Create,
	patternTime = 6.28,
	DisableInput = DisableInput,
}
return player
