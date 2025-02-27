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
		Version: 26.02.2025 - INITIAL PUBLIC RELEASE
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

local CS = game:GetService("CollectionService")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local SrvrEvents = game.ReplicatedStorage.ABSZERO.Decibel.Events
local playerCam = workspace.CurrentCamera

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
	
	local pos1 = raycast.Position -- initial point where obstruction raycast hits
	local pos2 -- resulting position of reverse raycast
	local vect = pos1 - target.Position
	local depthCast = workspace:Raycast(target.Position, vect, depthCheckParams)
	if depthCast ~= nil then
		pos2 = depthCast.Position
		if findDist then
			return (pos1-pos2).Magnitude -- depth
		else
			return pos2
		end
	end
	
end

-- not my code, ONLY for debugging
function VisualizeRay(origin,hit) -- origin = start position of ray, hit = hit position of ray
	local mag = (origin - hit).magnitude -- magnitude between points
	local VisualizePart = Instance.new("Part")
	VisualizePart.Anchored = true
	VisualizePart.CanCollide = false
	VisualizePart.Size = Vector3.new(0.1, 0.1, mag)
	VisualizePart.CFrame = CFrame.lookAt(origin, hit) * CFrame.new(0, 0, -mag/2)
	VisualizePart.Color = Color3.new(0, 1, 1)
	VisualizePart.Material = Enum.Material.SmoothPlastic
	VisualizePart.Transparency = 0.8
	VisualizePart.Parent = game.Workspace
	delay(1/DeciConfig.getReverbSetting("calcsPerSecond"), function()
		VisualizePart:Destroy()
	end)
end

-- PRI FUNCTIONS -- 

function muffCalcs(source, raycast)
	local depth = checkObjectDepth(raycast, source, true)
	local data = DeciConfig.matCheck(raycast.Instance.Material.Name)
	local eq = source:FindFirstChildOfClass("AudioEqualizer")
	if DeciConfig.getSysSetting("showMuffRaycasts") then
		VisualizeRay(playerCam.CFrame.Position, source.Position)
	end
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
	
	local emitterSrc = Instance.new("AudioEmitter", emitterObj)
	local audRevEffect = Instance.new("AudioReverb", emitterObj)
	local audMuffEffect = Instance.new("AudioEqualizer", emitterObj)
	local wireSrcRev = Instance.new("Wire", emitterObj)
	local wireRevMff = Instance.new("Wire", emitterObj)
	local wireMffOut = Instance.new("Wire", emitterObj)
	wireSrcRev.SourceInstance = source:FindFirstChildOfClass("AudioPlayer")
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
		-- maybe update other stuff
	end)
end
SrvrEvents.startClock:FireServer()
game.ReplicatedStorage.ABSZERO.Decibel.Events.DeciHeartbeat.OnClientEvent:Connect(function()
	local start = os.clock()
	for _, source in CS:GetTagged("AZERO_DECI_SOURCE") do
		task.spawn(function()
		local folder = source:FindFirstChildOfClass("Folder"):FindFirstChildOfClass("Part")
		local camPos = playerCam.CFrame.Position
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
			--print(reverbObject.WetLevel)
		end
		end)
	end
	if DeciConfig.getSysSetting("debugPrintsEnabled") then
		print("Execution Time of Previous Tick: " .. (math.floor((os.clock()-start)*100000))/100 .. "ms")
		if 1 / ((math.floor((os.clock()-start)*100))/100) <= DeciConfig.getReverbSetting("calcsPerSecond") then
			warn("CALCULATIONS EXCEEDING HEARTBEAT EXECUTION TIME -- FIX IMMEDIATELY")
		end
	end
end)