local size = util.GetCameraSize()

local function Cage(type, max, min, x_l, x_r)
	x_l = x_l or min
	x_r = x_r or min
	local bb = { { b = -max * size.y, t = -min * size.y,
		       l = -max * size.x, r =  max * size.x },
		     { t =  max * size.y, b =  min * size.y,
		       l = -max * size.x, r =  max * size.x },
		     { l = -max * size.x, r = -x_l * size.x,
		       b = -min * size.y, t =  min * size.y },
		     { r =  max * size.x, l =  x_r * size.x,
		       b = -min * size.y, t =  min * size.y }, }
	for i = 1, 4, 1 do eapi.NewShape(staticBody, nil, bb[i], type) end
end

local half = vector.Scale(size, 0.5)
local function OffScreen(pos)
	return pos.x < -half.x or pos.x > half.x
	    or pos.y < -half.y or pos.y > half.y
end

local store = { }

local function Square(x)
	return { b = -x, t = x, l = -x, r = x }
end

local function GetPos(actor, relativeTo)
	return eapi.GetPos(actor.body, relativeTo or gameWorld)
end

local function MakeSimpleTile(obj, z)
	local offset = obj.offset
	local size = obj.spriteSize
	return eapi.NewTile(obj.body, offset, size, obj.sprite, z or obj.z)
end

local function MakeTile(obj)
	obj.tile = MakeSimpleTile(obj)
	return obj.tile
end

local function SwapTile(obj, sprite, animType, FPS, startTime)
	eapi.Destroy(obj.tile)
	obj.sprite = sprite
	actor.MakeTile(obj)
	eapi.Animate(obj.tile, animType, FPS, startTime)
end

local function MakeShape(obj, bb)
	local shape = eapi.NewShape(obj.body, nil, bb or obj.bb, obj.class)
	obj.shape[shape] = shape
	store[shape] = obj
	return shape
end

local function Create(actor)
	actor.shape = { }
	actor.blinkIndex = 0
	local parent = actor.parentBody or gameWorld
	actor.body = eapi.NewBody(parent, actor.pos)
	actor.blinkTime = eapi.GetTime(actor.body)
	if actor.bb and actor.class then
		MakeShape(actor)
	end
	if actor.sprite then
		MakeTile(actor)
	end
	if actor.velocity then
		eapi.SetVel(actor.body, actor.velocity)
	end
	return actor	
end


local function DeleteShapeObject(shape)
	eapi.Destroy(shape)
	store[shape] = nil
end

local function DeleteShape(actor)
	util.Map(DeleteShapeObject, actor.shape)
	actor.shape = { }
end

local function Delete(actor)
	if actor.destroyed then return end
	util.Map(Delete, actor.children)
	util.MaybeCall(actor.OnDelete, actor)
	DeleteShape(actor)
	eapi.Destroy(actor.body)
	actor.destroyed = true
end

local function Link(child, parent)
	if parent.children == nil then parent.children = { } end
	eapi.Link(child.body, parent.body)
	parent.children[child] = child
end

local function ReapActor(rShape, aShape)
	Delete(store[aShape])
end

local function Blocker(bShape, aShape, box)
        local actor = store[aShape]
        local pos = GetPos(actor)

	local movex = math.abs(box.l) > math.abs(box.r) and box.r or box.l
	local movey = math.abs(box.b) > math.abs(box.t) and box.t or box.b

	if math.abs(movex) > math.abs(movey) then
		movex = 0
	else
		movey = 0
	end

	eapi.SetPos(actor.body, vector.Offset(pos, -movex, -movey))
	return false, actor
end

local function CloneBody(body, pos, vel)
	pos = vector.Add(eapi.GetPos(body, gameWorld), pos or vector.null)
	vel = vector.Add(eapi.GetVel(body), vel or vector.null)
	local clone = eapi.NewBody(gameWorld, pos)
	eapi.SetAcc(clone, vector.Scale(vel, -1))
	eapi.SetVel(clone, vel)
	return clone
end

local function SimpleCollide(type1, type2, Func, priority, update)
	update = (update == nil) and true or update
	local function Callback(shape1, shape2, resolve)
		if not resolve then return end
		Func(shape1, shape2, resolve)
	end
	eapi.Collide(gameWorld, type1, type2, Callback, update, priority or 10)
end

SimpleCollide("Reaper", "Mob", ReapActor)
SimpleCollide("Reaper", "Garbage", ReapActor)

local function DelayedDelete(obj, time)
	eapi.AddTimer(obj.body, time, function() Delete(obj) end)
	DeleteShape(obj)
end

local function GetDir(body)
	if eapi.__GetStep(body) == eapi.STEPFUNC_STD then
		return eapi.GetVel(body)
	elseif eapi.__GetStep(body) == eapi.STEPFUNC_ROT then
		local pos = eapi.GetPos(body)
		local vel = eapi.GetVel(body)
		local angle = (vel.x > 0) and 90 or -90
		return vector.Rotate(pos, angle)
	end
end

local function AnimateAngle(tile, angle, duration)
	eapi.AnimateAngle(tile, eapi.ANIM_CLAMP, vector.null,
			  vector.Radians(angle), duration, 0)
end

local function GetDirAdvanced(obj)
	if obj.GetDir then
		return obj.GetDir(obj)
	else
		return GetDir(obj.body)
	end
end

local function AnimateToVelocity(obj, turnSpeed, AnimateFn)
	local function AdjustAngle()
		AnimateToVelocity(obj, turnSpeed, AnimateFn)
	end
	local vel = GetDirAdvanced(obj)
	local diff = util.FixAngle(vector.Angle(vel) - obj.angle)
	local absDiff = math.abs(diff)
	if absDiff > 1 then
		local duration = turnSpeed * absDiff / 360		
		local scale = math.min(1, 0.1 / duration)
		obj.angle = obj.angle + scale * diff
		AnimateFn(obj, obj.angle, 0.1)
	end
	eapi.AddTimer(obj.body, 0.1, AdjustAngle)
end

local function BoxAtPos(pos, size)
	return { l = pos.x - size, r = pos.x + size,
		 b = pos.y - size, t = pos.y + size }		 
end

local function LoadFromMisc(frame)
	local fileName = { "image/misc.png", filter = true }
	return eapi.NewSpriteList(fileName, frame)
end

util.gradient = LoadFromMisc({ { 97, 1 }, { 30, 30 } })
util.triangle = LoadFromMisc({ { 192, 0 }, { 64, 64 } })
util.circle   = LoadFromMisc({ { 32, 32 }, { 32, 32 } })
util.radial   = LoadFromMisc({ { 0, 32 }, { 32, 32 } })
util.white    = LoadFromMisc({ { 65, 1 }, { 14, 14 } })
util.ribbon   = LoadFromMisc({ { 1, 129 }, { 382, 382 } })
util.shine    = LoadFromMisc({ { 256, 0 }, { 128, 128 } })
util.twinkle  = LoadFromMisc({ { 384, 0 }, { 64, 64 } })
util.pony     = LoadFromMisc({ { 384, 384 }, { 128, 128 } })
util.heart    = LoadFromMisc({ { 384, 256 }, { 128, 128 } })

local function ESC(keyDown)
	if keyDown then
		if state.level == "startup" then
			eapi.Quit()
		else
			util.Goto("startup")
		end
	end
end

input.Bind("Quit", false, ESC)

local paused = false
local pauseTile = nil
local pauseText = { }
local function Pause(keyDown)
	if keyDown then
		if paused then		
			util.Map(eapi.Destroy, pauseText)
			eapi.Destroy(pauseTile)
			eapi.Resume(gameWorld)
			eapi.ResumeMusic()
		else
			eapi.Pause(gameWorld)
			local pos = { x = -48, y = -232 }
			pauseText = util.PrintOrange(pos, "-= PAUSED =-", 9995)
			local tint = { r = 0.0, g = 0.0, b = 0.0, a = 0.75 }
			pauseTile = actor.FillScreen(util.white, 9990, tint)
			eapi.PauseMusic()
		end
		paused = not paused
	end
end

input.Bind("Pause", false, Pause)

local function ScaleTo(tile, pos, size, time)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, pos, time, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, size, time, 0)
end

local function FillScreen(sprite, z, color, body, adjust)
	adjust = adjust or 1.0
	body = body or staticBody
	local size = vector.Scale(actor.screenSize, adjust)
	local offset = vector.Scale(size, -0.5)
	local tile = eapi.NewTile(body, offset, size, sprite, z)
	if color then eapi.SetColor(tile, color) end
	return tile
end

local function LoadSprite(fileName, size)
	return eapi.ChopImage({ fileName, filter = true }, size)
end

local circleDstSize = { x = 8, y = 8 }
local circleDstOffset = { x = -4, y = -4 }

local circleSrcSize = { x = 128, y = 128 }
local circleSrcOffset = { x = -64, y = -64 }

local function AddProgressCircle(player, color, displace)
	displace = displace or vector.null
	color = color or { r = 1.0, g = 0.75, b = 0.0, a = 0.25 }

	local z = player.z - 0.00001
	local size = circleSrcSize
	local offset = circleSrcOffset

	local body = eapi.NewBody(player.body, displace)
	player.circle = eapi.NewTile(body, offset, size, util.shine, z)
	util.AnimateRotation(player.circle, 8)
	eapi.SetColor(player.circle, color)
end

local function ShrinkCircle()
	local tile = player.obj.circle
	local time = player.patternTime
	eapi.SetPos(tile, circleSrcOffset)
	eapi.SetSize(tile, circleSrcSize)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, circleDstOffset, time, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, circleDstSize, time, 0)
end

local star = string.char(143)
local allStar = "" .. star .. star .. star

local function FormatScore(score)
	if not score then
		return "N/A"
	elseif score == 0 then
		return allStar
	else
		return score
	end
end

actor = {
	star = star,
	store = store,
	ScaleTo = ScaleTo,
	BoxAtPos = BoxAtPos,
	CloneBody = CloneBody,
	MakeShape = MakeShape,
	FillScreen = FillScreen,
	FormatScore = FormatScore,
	SimpleCollide = SimpleCollide,
	DelayedDelete = DelayedDelete,
	ShrinkCircle = ShrinkCircle,
	AddProgressCircle = AddProgressCircle,
	AnimateToVelocity = AnimateToVelocity,
	screenSize = { x = Cfg.screenWidth, y = Cfg.screenHeight },
	AnimateAngle = AnimateAngle,
	DeleteShape = DeleteShape,
	LoadSprite = LoadSprite,
	OffScreen = OffScreen,
	MakeTile = MakeTile,
	SwapTile = SwapTile,
	Blocker = Blocker,
	GetDir = GetDir,
	Create = Create,
	Square = Square,
	Delete = Delete,
	GetPos = GetPos,
	Link = Link,
	Cage = Cage,
}
return actor
