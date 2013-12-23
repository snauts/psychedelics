local rayImg = actor.LoadSprite("image/rays.png", { 256, 256 })

local function Start()
	local size = { x = 800, y = 800 }
	local offset = { x = -400, y = -400 }
	for z = 0, 1, 0.5 do
		local color = { r = 1.0 * z, g = 0.2 * z, b = 1.0 - 0.6 * z }
		local tile = eapi.NewTile(staticBody, offset, size, rayImg, z)
		eapi.Animate(tile, eapi.ANIM_LOOP, 32 + 16 * z, 0)
		util.RotateTile(tile, z * 180)
		eapi.SetColor(tile, color)
	end
end

local screen = nil
local blinkTime = 0
local blinkIndex = 0
local blinkIntensity = 0

local function FadeBlinkScreen(color)
	local time = 0.5 * blinkTime
	color.a = 0.0
	eapi.SetColor(screen, color)
	color.a = blinkIntensity
	eapi.AnimateColor(screen, eapi.ANIM_REVERSE_CLAMP, color, time, 0)
end

local blinkText = nil
local blinkTextTimer = nil

local function DestroyBlinkText()
	if blinkText then
		eapi.CancelTimer(blinkTextTimer)
		util.Map(eapi.Destroy, blinkText)
		blinkText = nil
	end
end

local function CenterText(text, yOffset)
	local pos = util.TextCenter(text, util.defaultFontset)
	pos = vector.Offset(pos, 0, yOffset or 0)
	return util.PrintOrange(pos, text, nil, nil, 0)
end

local function BlinkText()
	DestroyBlinkText()
	blinkTextTimer = eapi.AddTimer(staticBody, 1, DestroyBlinkText)
	local text = "Flickering: " .. (state.blink and "on" or "off")
	blinkText = CenterText(text, -228)
end

local function ToggleBlink(keyDown)
	if keyDown then 
		state.blink = not state.blink
		BlinkText()
	end
end

input.Bind("Blink", false, ToggleBlink)

local function Blink(interval, intensity)
	blinkTime = interval
	blinkIntensity = intensity
	local function Flicker()
		local color = explode.rainbow[blinkIndex + 1]
		blinkIndex = (blinkIndex + 1) % #explode.rainbow
		eapi.AddTimer(staticBody, blinkTime, Flicker)
		if state.blink then
			FadeBlinkScreen(color)
		end
	end
	if not screen then
		local size = { x = 1000, y = 600 }
		local pos = { x = -500, y = -300 }
		screen = eapi.NewTile(staticBody, pos, size, util.white, -1000)
		eapi.SetColor(screen, util.invisible)
		Flicker()
	end
end

local speed = 0.1
local magnitue = 5
local radius = magnitue / speed
local side = 2 * radius * math.cos(vector.Radians(18))
local cameraDir = vector.Rotate({ x = 0, y = -side }, -18)

local function Shake()
	local function ChangeDirection()
		if ribbons.stopShake then return end
		local pos = eapi.GetPos(camera)
		eapi.SetVel(camera, cameraDir)
		cameraDir = vector.Rotate(cameraDir, 144)
		eapi.AddTimer(camera, speed, ChangeDirection)
		eapi.SetPos(camera, vector.Normalize(pos, magnitue))
	end
	eapi.SetVel(camera, { x = 0, y = radius })
	eapi.AddTimer(camera, speed, ChangeDirection)
end

local function ShowHelpText(obj, tip)
	obj.text = CenterText(tip, 228)
end

local black = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 }
local function BigBlackCenter(pos, message, z)
	return util.Print(pos, message, black, z, staticBody, util.bigFontset)
end

local textRotateAngle = 8
local function ScaleTextTile(tile)
	local pos = eapi.GetPos(tile)
	local size = eapi.GetSize(tile)
	eapi.AnimatePos(tile, eapi.ANIM_CLAMP, vector.Scale(pos, 2), 0.5, 0)
	eapi.AnimateSize(tile, eapi.ANIM_CLAMP, vector.Scale(size, 2), 0.5, 0)
	util.AnimateRotation(tile, textRotateAngle)
end

messages = { 
	{
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
	},
	{
		"Pony",
		"Stolen",
		"Evija",
		"Angry",
		"Rats",
		"Responsible",
		"Revenge",
		"Imminient",
		"Flying",
		"Crazy",
		"Rodents",
		"Panic",
		"Flee",
		"Hastily",
		"Soon",
		"Friends",
		"Reunite",
	},
	{
		"Rats",
		"Harmless",
		"Only",
		"Imagination",
		"Danger",
		"Nonexistent",
		"Boggies",
		"Unmasked",
		"Hope",
		"Established",
		"Worries",
		"Fading",
		"Mind",
		"Cleared",
		"Happiness",
		"Aquired",
	}
}

local function Flash(level, index)
	local size = { x = 1000, y = 600 }
	local pos = { x = -600, y = -300 }
	local message = messages[level][index]
	local tile = eapi.NewTile(staticBody, pos, size, util.white, -900)
	eapi.SetColor(tile, { r = 1.0, g = 1.0, b = 1.0, a =  1.0 })
	eapi.AnimateColor(tile, eapi.ANIM_CLAMP, util.invisible, 0.5, 0)
	eapi.AddTimer(staticBody, 0.5, function() eapi.Destroy(tile) end)	
	eapi.PlaySound(gameWorld, "sound/hisss.ogg")
	timing.Progress(level, index)
	if message then
		local pos = util.TextCenter(message, util.bigFontset)
		local flashTiles = BigBlackCenter(pos, message, -800)
		util.Map(ScaleTextTile, flashTiles)
		textRotateAngle = -textRotateAngle
		local function Destroy() 
			util.Map(eapi.Destroy, flashTiles)
		end
		eapi.AddTimer(staticBody, 0.5, Destroy)
	end	
end

ribbons = {
	Start = Start,
	Blink = Blink,
	Flash = Flash,
	Shake = Shake,
	CenterText = CenterText,
	ShowHelpText = ShowHelpText,
	msg = messages,
}
return ribbons
