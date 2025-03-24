--[[
 ________  _______   ________  ___  ________  _______   ___          
|\   ___ \|\  ___ \ |\   ____\|\  \|\   __  \|\  ___ \ |\  \         
\ \  \_|\ \ \   __/|\ \  \___|\ \  \ \  \|\ /\ \   __/|\ \  \        
 \ \  \ \\ \ \  \_|/_\ \  \    \ \  \ \   __  \ \  \_|/_\ \  \       
  \ \  \_\\ \ \  \_|\ \ \  \____\ \  \ \  \|\  \ \  \_|\ \ \  \____  
   \ \_______\ \_______\ \_______\ \__\ \_______\ \_______\ \_______\
    \|_______|\|_______|\|_______|\|__|\|_______|\|_______|\|_______|
    
		DYNAMIC SOUND MODULE - SERVER SCRIPT
		Made By: mochino_mocha
		Version: 1.01.00 - MINOR PATCH 1
 ----------------------------------------------------------------
							  WARNING
 ----------------------------------------------------------------
  	DO NOT EDIT ANY CODE LISTED HERE FOR ANY REASON
	IT MAY BREAK AND I AM NOT RESPONSIBLE FOR YOUR ACTIONS
	IF IT DOES BREAK, A FRESH INSTALL WILL LIKELY BE NEEDED
]]

-- VARIABLE LIBRARY --
if game:GetService("RunService"):IsClient() then
	error("DECISERVER CANNOT RUN ON CLIENT")
end
local DeciConfig = require(game.ReplicatedStorage.ABSZERO.Decibel.DeciConfig)
if not DeciConfig.getSysSetting("deciEnabled") then
	error("DECISERVER DISABLED - CHECK CONFIG SETTINGS")
end
print("Game Load Complete - DECIBEL Server Online")

local CS = game:GetService("CollectionService")
local RS = game:GetService("RunService")
local Events = game.ReplicatedStorage.ABSZERO.Decibel.Events
local DeciClockEnabled = true
local debugPrintsEnabled = DeciConfig.getSysSetting("debugPrintsEnabled")
local calcsPerSecond = DeciConfig.getReverbSetting("calcsPerSecond")
local numBounces = DeciConfig.getReverbSetting("numBounces")
local numRays = DeciConfig.getReverbSetting("numRays")

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = CS:GetTagged("AZERO_DECI_OBJECT")
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true

local reverbCalcStorage = {}

-- SEC FUNCTIONS --
local function getRandomVector()
	local randomVector = Vector3.new(
		math.random(-math.pi * 90, math.pi * 90),
		math.random(-math.pi * 90, math.pi * 90),
		math.random(-math.pi * 90, math.pi * 90)
	)
	return randomVector
end
local function findAnglefromVector(a, b)
	return math.deg(math.acos(a:Dot(b) / (a.Magnitude * b.Magnitude)))
end
local function findReflectionVector(a, b)
	return a - (2*a:Dot(b)*b)
end

local function findLowestNumber(array)
	local lowest = math.huge
	local pos = nil
	for i, v in pairs(array) do
		if array[i] < lowest then
			lowest = array[i]
			pos = i
		end
	end
	return pos
end

local function GetDistanceWeight(Distance: number, maxDist: number) -- experiment with maxdist later
	maxDist = 100
	return math.pow(math.log(math.clamp(Distance, 1, maxDist), 2.7), 1.6)-.8
end


-- Primary Functions
function reverbCalcs(source)
	local raycastStorage = {}
	local distWeight = 0
	local avgRef = 0
	local avgDens = 0
	local refCounter = 0
	local decay
	local diff
	local dens
	local wet
	local dry -- maybe dont change? idk
	
	-- Raycasting --
	while #raycastStorage < numRays do
		local index = #raycastStorage + 1
		raycastStorage[index] = 0
		local initVect = getRandomVector()
		local initCast = workspace:Raycast(source.Position, initVect, rayParams)
		local rayTable = {
			raycasts = {
				initCast
			},
			rayAbsorbed = false,
			ignoreRay = false,
			rayDist = 0,
			rayDens = 0,
			refCounter = 0,
			rayRef = 0
		}
		if initCast ~= nil then
			local prevCast = initCast
			local prevVect = initVect
			rayTable["rayDist"]  = (source.Position - initCast.Position).Magnitude
			rayTable["rayDens"]  = DeciConfig.matCheck(initCast.Material.Name)["matDens"]
			while #rayTable["raycasts"] <= numBounces do
				local result = 0
				if DeciConfig.matCheck(prevCast.Material.Name)["matRef"] > math.random(0, 1) and not rayTable["rayAbsorbed"] then
					local rebounceVect = findReflectionVector(prevVect, prevCast.Normal)
					local rebounceCast = workspace:Raycast(prevCast.Position, rebounceVect, rayParams)
					if rebounceCast ~= nil then
						rayTable["rayDist"] += (prevCast.Position - rebounceCast.Position).Magnitude
						rayTable["rayDens"] += (DeciConfig.matCheck(rebounceCast.Material.Name)["matDens"])/2
						rayTable["rayRef"] += (1-DeciConfig.matCheck(rebounceCast.Material.Name)["matRef"])/2
						prevCast = rebounceCast
						prevVect = rebounceVect
						result = prevCast
					end
				else
					rayTable["rayAbsorbed"] = true
				end
				rayTable["raycasts"][#rayTable["raycasts"] + 1] = result
			end
			local rayCounter = 1
			for _, v in rayTable["raycasts"] do
				if v ~= 0 then
					rayCounter = rayCounter+1
				end
			end
			rayTable["rayDist"]  = rayTable["rayDist"] / (rayCounter+1)
			rayTable["rayDens"]  = rayTable["rayDens"] / (rayCounter+1)
			rayTable["rayRef"] = rayTable["rayRef"] / (rayCounter+1)
			rayTable["refCounter"] = rayCounter / (rayCounter+1)
		else
			rayTable["ignoreRay"] = true
			while #rayTable["raycasts"] <= numBounces do
				rayTable["raycasts"][#rayTable["raycasts"] + 1] = 0
			end
		end
		raycastStorage[index] = rayTable
	end
	-- Data Mapping --
	for _, v in raycastStorage do
		distWeight = distWeight + GetDistanceWeight(v["rayDist"])
		avgRef = avgRef + v["rayRef"]
		avgDens = avgDens + v["rayDens"]
		refCounter = refCounter + v["refCounter"]
	end
	decay = DeciConfig.mapData("decay", (distWeight/#raycastStorage), nil)
	diff = DeciConfig.mapData("diff", (refCounter/#raycastStorage), (avgRef/#raycastStorage))
	dens = DeciConfig.mapData("dens",(avgDens/#raycastStorage), nil)
	wet = DeciConfig.mapData("wet", (refCounter/#raycastStorage),(distWeight/#raycastStorage))
	local results = {
		decay,
		diff,
		dens,
		wet
	}
	return results
end

function startDecibelClock()
	DeciClockEnabled = true
	local interval = 1 / calcsPerSecond
	local ctr = 0
	game:GetService("RunService").Heartbeat:Connect(function(delta)
		ctr = ctr+delta
		if ctr >= interval then
			ctr = ctr-interval
			if not DeciClockEnabled then
				return
			end
			reverbCalcStorage = {}
			game.ReplicatedStorage.ABSZERO.Decibel.Events.DeciHeartbeat:FireAllClients()
		end
	end)
end

function getReverb(source)
	if reverbCalcStorage[source] then
		return reverbCalcStorage[source]
	else
		reverbCalcStorage[source] = reverbCalcs(source)
		return reverbCalcStorage[source]
	end
end
function startClock()
	startDecibelClock()
end
function stopClock()
	DeciClockEnabled = false
end

Events.stopClock.OnServerEvent:Connect(function()
	stopClock()
end)
Events.startClock.OnServerEvent:Connect(function()
	startClock()
end)
Events.getReverb.OnServerInvoke = function(player, source)
	return getReverb(source)
end