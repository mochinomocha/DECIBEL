--[[
 ________  _______   ________  ___  ________  _______   ___          
|\   ___ \|\  ___ \ |\   ____\|\  \|\   __  \|\  ___ \ |\  \         
\ \  \_|\ \ \   __/|\ \  \___|\ \  \ \  \|\ /\ \   __/|\ \  \        
 \ \  \ \\ \ \  \_|/_\ \  \    \ \  \ \   __  \ \  \_|/_\ \  \       
  \ \  \_\\ \ \  \_|\ \ \  \____\ \  \ \  \|\  \ \  \_|\ \ \  \____  
   \ \_______\ \_______\ \_______\ \__\ \_______\ \_______\ \_______\
    \|_______|\|_______|\|_______|\|__|\|_______|\|_______|\|_______|
    
		DYNAMIC SOUND MODULE - CLIENT SCRIPT
		Made By: mochino_mocha
		Version: 1.01.00 - MINOR PATCH 1
 ----------------------------------------------------------------
							  WARNING
 ----------------------------------------------------------------
  	DO NOT EDIT ANY CODE LISTED HERE FOR ANY REASON
	IT MAY BREAK AND I AM NOT RESPONSIBLE FOR YOUR ACTIONS
	IF IT DOES BREAK, A FRESH INSTALL WILL LIKELY BE NEEDED
]]

-- INITIALIZATION -- 
game.Players.LocalPlayer.CharacterAdded:Wait()
local audPlayerListener = Instance.new("AudioListener", workspace.CurrentCamera)
local audPlayerOutput = Instance.new("AudioDeviceOutput", workspace.CurrentCamera)
local wireListenerOut = Instance.new("Wire", workspace.CurrentCamera)
wireListenerOut.SourceInstance = audPlayerListener
wireListenerOut.TargetInstance = audPlayerOutput

if game:GetService("RunService"):IsServer() then
	error("DECICLIENT CANNOT RUN ON SERVER")
end

local DeciConfig = require(game.ReplicatedStorage.ABSZERO.Decibel.DeciConfig)
if not DeciConfig.getSysSetting("deciEnabled") then
	error("DECICLIENT DISABLED - CHECK CONFIG SETTINGS")
end

local Humanoid = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
repeat wait() until game:IsLoaded()
print("Game Load Complete - DECIBEL Client Online")

-- VARIABLE LIBRARY --
local soundLibrary = {}

local effectDictionary = {
	"AudioChorus",
	"AudioCompressor",
	"AudioDistortion",
	"AudioEcho",
	"AudioEqualizer",
	"AudioFader",
	"AudioFilter",
	"AudioFlanger",
	"AudioLimiter",
	"AudioPitchShifter",
	"AudioReverb"
}

local CS = game:GetService("CollectionService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local SrvrEvents = game.ReplicatedStorage.ABSZERO.Decibel.Events
local playerCam = workspace.CurrentCamera
local volChecker = Instance.new("AudioListener", playerCam)
local debugPrintsEnabled = DeciConfig.getSysSetting("debugPrintsEnabled")
local calcsPerSecond = DeciConfig.getReverbSetting("calcsPerSecond")

local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = CS:GetTagged("AZERO_DECI_OBJECT")
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true

-- SEC FUNCTIONS --
local function checkObjectDepth(raycast, target, findDist)
	local depthCheckParams = RaycastParams.new()
	depthCheckParams.FilterDescendantsInstances = {
		raycast.Instance
	}
	depthCheckParams.FilterType = Enum.RaycastFilterType.Include
	
	local pos1 = raycast.Position
	local pos2
	local vect = pos1 - target.Position
	local depthCast = workspace:Raycast(target.Position, vect, depthCheckParams)
	if depthCast ~= nil then
		pos2 = depthCast.Position
		if findDist then
			return (pos1-pos2).Magnitude
		else
			return pos2
		end
	end
	
end

-- PRI FUNCTIONS -- 

function muffCalcs(source, raycast)
	local depth = checkObjectDepth(raycast, source, true)
	local data = DeciConfig.matCheck(raycast.Instance.Material.Name)
	local eq = source:FindFirstChildOfClass("AudioEqualizer")
	eq.HighGain = DeciConfig.mapData("eqHigh", data["matDens"], depth)
	eq.MidGain = DeciConfig.mapData("eqMid", data["matDens"], depth)
	eq.LowGain = DeciConfig.mapData("eqLow", data["matDens"], depth)
end

for _, source in CS:GetTagged("AZERO_DECI_SOURCE") do
	local sourcePos = source.Position
	local srcFolder = Instance.new("Folder", source)
	srcFolder.Name = "DeciAssetFolder"
	local emitterObj = Instance.new("Part", srcFolder)
	emitterObj.Position = sourcePos
	emitterObj.Transparency = 1
	emitterObj.Anchored = true
	emitterObj.CanCollide = false
	emitterObj.CanTouch = false
	emitterObj.CanQuery = false
	emitterObj.Anchored = true
	
	local prevObject = source:FindFirstChildOfClass("AudioPlayer")
	for _, obj in source:GetDescendants() do
		if table.find(effectDictionary, obj.ClassName) then
		local tempWire = Instance.new("Wire", srcFolder)
		local tempObj = obj:Clone()
		tempObj.Parent = srcFolder
		tempObj.Name = tempObj.ClassName
		tempWire.SourceInstance = prevObject
		tempWire.TargetInstance = tempObj
		prevObject = tempObj
		end
	end
	local emitterSrc = Instance.new("AudioEmitter", emitterObj)
	local audRevEffect = Instance.new("AudioReverb", emitterObj)
	local audMuffEffect = Instance.new("AudioEqualizer", emitterObj)
	local wireSrcRev = Instance.new("Wire", emitterObj)
	local wireRevMff = Instance.new("Wire", emitterObj)
	local wireMffOut = Instance.new("Wire", emitterObj)
	wireSrcRev.SourceInstance = prevObject
	wireSrcRev.TargetInstance = audRevEffect
	wireRevMff.SourceInstance = audRevEffect
	wireRevMff.TargetInstance = audMuffEffect
	wireMffOut.SourceInstance = audMuffEffect
	wireMffOut.TargetInstance = emitterSrc
	
	if source:GetAttribute("DeciReverbEnabled") ~= true then
		audRevEffect.Bypass = true
	end
	
	local camPos = playerCam.CFrame.Position
	source.Changed:Connect(function()
		emitterObj.Position = source.Position
	end)
end

SrvrEvents.startClock:FireServer()

game.ReplicatedStorage.ABSZERO.Decibel.Events.DeciHeartbeat.OnClientEvent:Connect(function()
	local distCheckThreshold = DeciConfig.getSysSetting("distCheckThreshold")
	local bypassDistCheck = DeciConfig.getSysSetting("bypassDistCheck")
	local start = os.clock()
	for _, source in CS:GetTagged("AZERO_DECI_SOURCE") do
		task.spawn(function()
		local folder = source:FindFirstChildOfClass("Folder"):FindFirstChildOfClass("Part")
		local camPos = playerCam.CFrame.Position
		print(volChecker:GetAudibilityFor(folder:FindFirstChildOfClass("AudioEmitter")) > distCheckThreshold)
		if volChecker:getAudibilityFor(folder:FindFirstChildOfClass("AudioEmitter")) > distCheckThreshold or bypassDistCheck then
			local playerVector = source.Position - camPos
			local checkObstruction = workspace:Raycast(camPos, playerVector, rayParams)
			if checkObstruction then
				muffCalcs(source:FindFirstChild("DeciAssetFolder"):FindFirstChildOfClass("Part"), checkObstruction)
				folder:FindFirstChildOfClass("AudioEqualizer").Bypass = false
			else
				folder:FindFirstChildOfClass("AudioEqualizer").Bypass = true
			end
			if source:GetAttribute("DeciReverbEnabled") == true then
				local reverbResultTable = SrvrEvents.getReverb:InvokeServer(source)
				local reverbObject = folder:FindFirstChildOfClass("AudioReverb")
				reverbObject.DecayTime = reverbResultTable[1]
				reverbObject.Diffusion = reverbResultTable[2]
				reverbObject.Density = reverbResultTable[3]
				reverbObject.WetLevel = reverbResultTable[4]
			end
		end
		end)
	end
	if debugPrintsEnabled then
		print("Execution Time of Previous Tick: " .. (math.floor((os.clock()-start)*100000))/100 .. "ms")
		if 1 / ((math.floor((os.clock()-start)*100))/100) <= calcsPerSecond then
			warn("DECIBEL ERROR -- CALCULATIONS EXCEEDING HEARTBEAT EXECUTION TIME -- FIX IMMEDIATELY")
		end
	end
end)