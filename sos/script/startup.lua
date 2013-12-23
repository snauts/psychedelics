dofile("script/ribbons.lua")
dofile("script/explode.lua")

local function Level(name)	
	local function Cheat()
		util.Goto(name)
	end
	return util.KeyDown(Cheat)
end

local levels = { { key = "Polar",   goto = "polar",   y =  28 },
		 { key = "PonPon",  goto = "pon-pon", y =  -8 },
		 { key = "PifPaf",  goto = "pif-paf", y = -44 } }

local function Box(size, offset, body)
	local light = 0.8
	body = body or staticBody

	local function Rectangle(size, offset, light)
		local tile = eapi.NewTile(body, offset, size, util.white, 95)
		eapi.SetColor(tile, util.SetColorAlpha(util.Gray(light), 0.2))
		return tile
	end

	Rectangle(size, offset, light)
	local sizeA = { x = size.x + 4, y = 2 }
	local sizeB = { x = 2, y = size.y }

	Rectangle(sizeA, vector.Offset(offset, -2, -2), light - 0.3)
	Rectangle(sizeB, vector.Offset(offset, -2,  0), light + 0.3)

	Rectangle(sizeA, vector.Offset(offset, -2, size.y), light + 0.3)
	Rectangle(sizeB, vector.Offset(offset, size.x, 0),  light - 0.3)
end

Box({ x = 128, y = 128 }, { x = -64, y = -64 })

local function LocY(i)
	return 52 - i * 24
end

for i = 1, #levels, 1 do
	local level = levels[i]
	local textPos = { x = -48, y = level.y }
	local name = "     " .. level.key
	if state.progress >= i then
		util.PrintOrange(textPos, name, nil, nil, 0)
	else
		util.PrintShadow(textPos, name, util.Gray(0.1), nil, nil, 0)
	end
	util.PrintShadow(textPos, ">>>", util.Gray(0.1), 99, nil, 0)
end

local function AnimateBlinking(tiles, t, dtFn)
	local function Blink(tile)
		local dt = -util.MaybeCall(dtFn)
		local color = eapi.GetColor(tile)
		color = util.SetColorAlpha(color, 0.1)
		eapi.AnimateColor(tile, eapi.ANIM_REVERSE_LOOP, color, t, dt)
	end
	util.Map(Blink, tiles)
end

local cursorTiles = { }
local cursorLocation = 0

local function PrintCursor()
	for i = 0, 16, 8 do
		local pos = { x = -48 + i, y = levels[cursorLocation + 1].y }
		local tiles = util.PrintOrange(pos, ">", nil, nil, 0)		
		cursorTiles = util.JoinTables(cursorTiles, tiles)
		AnimateBlinking(tiles, 0.4, 0.4 * (1 - (i / 16)))
	end
end

PrintCursor()

local function MoveCursor(y)
	local function Move(tile)
		eapi.SetPos(tile, { x = eapi.GetPos(tile).x, y = y })
	end
	util.Map(Move, cursorTiles)	
end

local lastState = nil

local function SomeChar()
	return util.RandomElement({ "@", "#", "$", "%", "&", "*" })
end

local red = { r = 0.6, g = 0.0, b = 0.0, a = 1.0 }
local orange = { r = 0.8, g = 0.4, b = 0.0, a = 0.8 }

local function SweepBody(oldState, newState)
	if oldState then 
		if oldState.state == "roll" then
			oldState.state = "wait"
		else
			local body = oldState.body
			eapi.SetAcc(body, { x = 1600, y = 0 })
			eapi.SetVel(body, { x = 400, y = 0 })
			util.DelayedDestroy(body, 0.5)
		end
	end
	lastState = newState
end

local function RandomDir()
	return util.Sign(math.random() - 0.5)
end

local function Jitter(tiles)
	local t = 0.1
	local function Skew(tile)
		local pos = eapi.GetPos(tile)
		local dt = -t * math.random()
		pos = vector.Offset(pos, RandomDir(), RandomDir())
		eapi.AnimatePos(tile, eapi.ANIM_REVERSE_LOOP, pos, t, dt)
	end
	util.Map(Skew, tiles)
end

local function TextShadow(newState, pos, text, i, color, blink)
	local rate = 0.5
	local body = newState.body
	local offset = vector.Offset(pos, -32, 0)
	local size = { x = 192, y = 16 }
	local tile = eapi.NewTile(body, offset, size, util.radial, 95)
	eapi.SetColor(tile, color)
	if blink then
		AnimateBlinking({ tile }, rate, rate * i / #text)
	end	
end

local scoreTiles = { }
local function DisplayLocalScore(i)
	util.Map(eapi.Destroy, scoreTiles)
	local scoreStr = actor.FormatScore(state.scores[i])
	local amount = levels[i].key .. " Best: " .. scoreStr
	local pos = { x = 398 - #amount * 8, y = 222 }
	scoreTiles = util.PrintOrange(pos, amount, nil, nil, 0)
end

local function DisplayMessageProgress(num)
	local text = ribbons.msg[num]
	local y = 0.25 * (#text * 16)
	local body = eapi.NewBody(gameWorld, { x = 0, y = -400 })
	local thisState = { body = body, state = "roll" }
	DisplayLocalScore(num)
	for i = 1, #text, 1 do
		local str = ""
		local pos = { x = 288, y = y }
		if state.msgProgress[num] >= i then
			util.PrintOrange(pos, text[i], nil, body, 0)
			TextShadow(thisState, pos, text, i, orange, false)	
		else
			for j = 1, #text[i], 1 do str = str .. SomeChar() end
			local tiles = util.PrintRed(pos, str, nil, body, 0)
			AnimateBlinking(tiles, 0.25, util.Random)		
			TextShadow(thisState, pos, text, i, red, true)	
			Jitter(tiles)
		end
		y = y - 16
	end 	
	local function Stop()
		eapi.SetVel(body, vector.null)
		if thisState.state == "roll" then
			thisState.state = "stay"
		else
			SweepBody(thisState, lastState)
		end
	end
	eapi.SetVel(body, { x = 0, y = 1600 })
	eapi.AddTimer(body, 0.25, Stop)
	SweepBody(lastState, thisState)
end

DisplayMessageProgress(cursorLocation + 1)

local function MenuNavigate(dir)
	return function(keyDown)
		if keyDown then
			local prevLocation = cursorLocation
			local progress = math.min(state.progress, 3)
			cursorLocation = (cursorLocation - dir) % progress
			MoveCursor(levels[cursorLocation + 1].y)
			local soundFile = "xylo" .. (dir + 3) / 2 .. ".ogg"
			eapi.PlaySound(gameWorld, "sound/" .. soundFile, 0, .2)
			if prevLocation ~= cursorLocation then
				DisplayMessageProgress(cursorLocation + 1)
			end
		end
	end
end

local function Select(keyDown)
	if keyDown then
		eapi.PlaySound(gameWorld, "sound/hisss.ogg")
		util.Goto(levels[cursorLocation + 1].goto)
	end
end

input.Bind("Up", false, MenuNavigate(1))		
input.Bind("Down", false, MenuNavigate(-1))		
input.Bind("Move", false, Select)		
input.Bind("Pause", false, Select)

local title = "Psychedelics"
local pos = vector.Offset(util.TextCenter(title, util.bigFontset), 0, 144)
util.PrintOrange(pos, title, 100, staticBody, shadow, util.bigFontset)
ribbons.CenterText("Life is just a ride.", -228)
eapi.FadeMusic(0.5)

local function WiggleStar(body, var)
	local speed = (50 + 50 * var) * util.Sign(math.random())
	local frequency = 0.5 + 0.5 * math.random()
	eapi.SetVel(body, { x = 0.5 * speed * frequency, y = -100 - 100 * var })
	local function Reverse()
		speed = -speed
		eapi.SetAcc(body, { x = speed, y = 0 })
		eapi.AddTimer(body, frequency, Reverse)
	end
	Reverse()
end

local function EmitStar(pos, var)
	local z = -10.5 + var
	local half = 0.5 * (1 + var)
	local size = vector.Scale({ x = 16, y = 16 }, half)
	local offset = vector.Scale({ x = -8, y = -8 }, half)
	local body = eapi.NewBody(gameWorld, pos)
	local tile = eapi.NewTile(body, offset, size, util.twinkle, z)
	local turnSpeed = (1 + math.random()) * util.Sign(math.random() - 0.5)
	eapi.SetColor(tile, util.Gray(0.6 + 0.2 * var))
	util.DelayedDestroy(body, (2.0 - var) * 3.0)
	util.AnimateRotation(tile, turnSpeed)
	WiggleStar(body, var)
end

local interval = 0.2
local function Snow()
	EmitStar({ x = math.random(-400, 400), y = 272 }, math.random())
	interval = math.max(interval * 0.95, 0.01)
	eapi.AddTimer(staticBody, interval, Snow)
end
Snow()

local totalAmount = "Total Best: " .. actor.FormatScore(state.total)
util.PrintOrange({ x = -398, y = 222 }, totalAmount, nil, nil, 0)
