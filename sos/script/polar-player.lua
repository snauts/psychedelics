local function Spin(player, angle, dir)
	local start = dir > 0 and 0 or 31
	local last = 31 - start
	local this = eapi.GetFrame(player.tile)
	eapi.AnimateFrame(player.tile, eapi.ANIM_LOOP, start, last, this, 0.5)

	eapi.SetVel(player.body, { x = dir, y = dir })
	util.RotateTile(player.tile, angle)
	local start = vector.Radians(angle)
	eapi.AnimateAngle(player.tile, eapi.ANIM_LOOP, vector.null,
			  start + dir * 2 * math.pi, 2 * math.pi, 0)
end

local function ChangeDirection(player, keyDown)
	if keyDown and not player.dirKey then
		local burstAngle = -60 * player.dir
		local pos = eapi.GetPos(player.body, gameWorld)
		Spin(player, vector.Angle(pos) + 90, player.dir)
		explode.Burst(pos, vector.Rotate(pos, burstAngle), 60)
		eapi.PlaySound(gameWorld, "sound/woosh.ogg")
		player.dir = -player.dir
	end
	player.dirKey = keyDown
end

local function Move(player)
	return function(keyDown)
		ChangeDirection(player, keyDown)
	end
end

local function FirstTap(player, Launch)
	return function(keyDown)
		if keyDown then
			actor.AddProgressCircle(player)
			input.Bind("Move", false, Move(player))
			ChangeDirection(player, keyDown)
			util.Map(eapi.Destroy, player.text)
			bomb.ResetTime()
			Launch()
		end
	end
end

local function EnableInput(player, Launch)
	input.Bind("Move", false, FirstTap(player, Launch))
	return player
end

local shipImg = actor.LoadSprite("image/ship.png", { 64, 64 })

local function Create(Launch)
	local obj = { z = 10,
		      dir = 1,
		      speed = 300,
		      dirKey = false,
		      sprite = shipImg,
		      class = "Player",
		      vel = vector.null,
		      moves = { 0, 0, 0, 0 },
		      pos = { x = 0, y = -200 },
		      offset = { x = -32, y = -32 },
		      parentBody = eapi.NewBody(gameWorld, vector.null),
		      bb = actor.Square(8) }	
	obj = actor.Create(obj)
	eapi.SetStepC(obj.body, eapi.STEPFUNC_ROT, 0)
	eapi.PlayMusic("sound/music.ogg", nil, 1.0, 1.0)
	local text = "\"Space\" - Change Direction"
	ribbons.ShowHelpText(obj, text)
	eapi.SetFrame(obj.tile, 16)
	player.obj = obj
	return EnableInput(obj, Launch)
end

player = {
	Create = Create,
	patternTime = 6.28,
}
return player
