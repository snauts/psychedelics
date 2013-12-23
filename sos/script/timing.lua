local NextPattern = nil
local patternIndex = 1
local msgIndex = 1

local function Schedule(delay)
	eapi.AddTimer(staticBody, delay, NextPattern)
end

local function AdvancePattern()
	patternIndex = patternIndex + 1
	bomb.ResetTime()
end

local function Test()
	return (bomb.GetTime() > player.patternTime)
end

local function CrunchPattern()
	timing.patternList[patternIndex]()
	if timing.Test() then
		AdvancePattern()
		ribbons.Flash(state.current, msgIndex)
		msgIndex = msgIndex + 1
	end	
end

local function Immediate(Function)
	return function()
		AdvancePattern()
		Schedule(0)
		Function()
	end
end

local function Delay(timeout)
	local function Reset()
		bomb.ResetTime()
	end
	return function()
		AdvancePattern()
		Schedule(timeout)
		eapi.AddTimer(staticBody, timeout, Reset)
	end
end

NextPattern = CrunchPattern

local function IncHits()
	state.hits = state.hits + 1
	state.levelScore = state.levelScore + 1
end

local function SelectScore(high, now)
	return high and math.min(high, now) or now
end

local function EndLevel(i)
	state.thisRun[i] = state.levelScore
	state.scores[i] = SelectScore(state.scores[i], state.thisRun[i])
end

local function Progress(num, index)
	index = index or 0
	state.current = num
	state.progress = math.max(state.progress, num)
	state.msgProgress[num] = math.max(state.msgProgress[num] or 0, index)
        local saveFile = io.open("saavgaam", "w")
        if saveFile then
		saveFile:write("state.progress = " .. state.progress .. "\n")
		if state.total then
			saveFile:write("state.total = " .. state.total .. "\n")
		end
		for i = 1, 3, 1 do
			local var = "state.msgProgress[" .. i .. "]="
			saveFile:write(var .. state.msgProgress[i] .. "\n")
			if state.scores[i] then
				local pfx = "state.scores[" .. i .. "]="
				saveFile:write(pfx .. state.scores[i] .. "\n")
			end
		end
		io.close(saveFile)
        end	
end

local function InsertDelays(patternList, delay)
	for i = 1, #patternList, 1 do
		timing.patternList[i * 2 - 1] = patternList[i]
		timing.patternList[i * 2] = timing.Delay(delay)
	end
end

timing = {	
	Test = Test,
	Delay = Delay,
	Progress = Progress,
	Schedule = Schedule,
	Start = CrunchPattern,
	Immediate = Immediate,	
	InsertDelays = InsertDelays,
	EndLevel = EndLevel,
	IncHits = IncHits,
	patternList = { },
}
return timing
