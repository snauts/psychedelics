dofile("script/ribbons.lua")
dofile("script/timing.lua")

local function GetRank()
	if state.hits <= 0 then
		return "kitten" -- I don't know if this is possible
	elseif state.hits <= 100 then
		return "gold"
	elseif state.hits <= 500 then
		return "silver"
	else
		return "bronze"
	end
end

util.BigTextCenter("The End")
ribbons.CenterText("Thank you for playing!", -32)
local msg = ""
if state.start == 1 then
	if not state.total or state.total >= state.hits then
		state.total = state.hits
	end
end
timing.Progress(4)

local function Flash(amount)
	return function(tile)
		local color = eapi.GetColor(tile)
		color = util.Map(function(x) return amount * x end, color)
		eapi.SetColor(tile, color)
	end
end

local function DoBlink(tiles)
	local amount = 0.5
	local function Blink()
		util.Map(Flash(amount), tiles)
		eapi.AddTimer(staticBody, 0.1, Blink)
		amount = 2.5 - amount
	end
	Blink()
end

local function NewBest(x, y)
	local pos = { x = x, y = y }
	local bestText = actor.star .. "NewBest" .. actor.star
	DoBlink(util.PrintOrange(pos, bestText, nil, nil, 0))
end

local y = -128
local function Text(xOffset, text, isBest)
	local pos = { x = -128 + xOffset, y = y }
	util.PrintOrange(pos, text, nil, nil, 0)
	if isBest then NewBest(40, y) end
	y = y - 16
end

local function GetTotalThisRun()
	if state.start == 1 then
		return state.hits
	else
		return nil
	end
end

local function HiScore(i)
	return state.thisRun[i] and (state.thisRun[i] <= state.scores[i])
end

local function HiScoreTotal()
	return (state.start == 1 and state.total and state.total <= state.hits)
end

local levelNames = { "Polar  ", "Pon-Pon", "Pif-Paf" }

Text(16, "Score this run...")
Text(0, "================================")
for i = 1, 3, 1 do
	local score = actor.FormatScore(state.thisRun[i])
	Text(32, levelNames[i] .. " : " .. score, HiScore(i))
end
Text(0, "--------------------------------")
Text(32, "Total   : " .. actor.FormatScore(GetTotalThisRun()), HiScoreTotal())
