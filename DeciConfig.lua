--[[
 ________  _______   ________  ___  ________  _______   ___          
|\   ___ \|\  ___ \ |\   ____\|\  \|\   __  \|\  ___ \ |\  \         
\ \  \_|\ \ \   __/|\ \  \___|\ \  \ \  \|\ /\ \   __/|\ \  \        
 \ \  \ \\ \ \  \_|/_\ \  \    \ \  \ \   __  \ \  \_|/_\ \  \       
  \ \  \_\\ \ \  \_|\ \ \  \____\ \  \ \  \|\  \ \  \_|\ \ \  \____  
   \ \_______\ \_______\ \_______\ \__\ \_______\ \_______\ \_______\
    \|_______|\|_______|\|_______|\|__|\|_______|\|_______|\|_______|
    
		DYNAMIC SOUND MODULE - CONFIGURATION FILE
		Made By: mochino_mocha
		Version: 1.01.00 - MINOR PATCH 1
 ----------------------------------------------------------------
						   INSTRUCTIONS
 ----------------------------------------------------------------
  	Hey hey! Thanks for installing DECIBEL, it means a lot!
	This file has a bunch of numbers and variables you can tweak to change the overall sound.
	Most of these should be pretty self explanatory, but here's a few things to note.
	You can add new materials by pasting the name, along with the reflectivity and density of the material.
	Here's a template for you!
	MaterialName = {matRef = (0.01 - 1), matDens = (0.01 - 1)},
	After you do that, DECI should take care of the rest!
	
	Please note that DECI is still in the VERY early stages of a public release, and I haven't tested everything yet -_-"
	If something breaks, please let me know so I can fix it, you'll be doing me a huge favor!
	If you have any other questions about this file, please contact me and I'll answer as soon as I can.
	Thanks, and enjoy!
	- Mocha
]]




local materialsLibrary = {
	Plastic = {matRef = 0.6, matDens = 0.5},
	SmoothPlastic = {matRef = 0.6, matDens = 0.5},
	Neon = {matRef = 0.95, matDens = 0.1},
	Wood = {matRef = 0.3, matDens = 0.6},
	WoodPlanks = {matRef = 0.35, matDens = 0.5},
	Marble = {matRef = 0.8, matDens = 0.8},
	Basalt = {matRef = 0.8, matDens = 0.7},
	Slate = {matRef = 0.8, matDens = 0.8},
	CrackedLava = {matRef = 0.8, matDens = 0.8},
	Limestone = {matRef = 0.8, matDens = 0.8},
	Concrete = {matRef = 0.3, matDens = 0.7},
	Granite = {matRef = 0.6, matDens = 0.9},
	Pavement = {matRef = 0.65, matDens = 0.75},
	Brick = {matRef = 0.3, matDens = 0.85},
	Pebble = {matRef = 0.35, matDens = 0.5},
	Cobblestone = {matRef = 0.35, matDens = 0.7},
	Rock = {matRef = 0.8, matDens = 0.8},
	Sandstone = {matRef = 0.8, matDens = 0.7},
	CorrodedMetal = {matRef = 0.75, matDens = 0.9},
	DiamondPlate = {matRef = 0.8, matDens = 1},
	Foil = {matRef = 0.7, matDens = 0.9},
	Metal = {matRef = 0.8, matDens = 1},
	Grass = {matRef = 0.3, matDens = 0.1},
	LeafyGrass = {matRef = 0.3, matDens = 0.1},
	Sand = {matRef = 0.45, matDens = 0.4},
	Fabric = {matRef = 0.05, matDens = 0.3},
	Snow = {matRef = 0.3, matDens = 0.1},
	Mud = {matRef = 0.25, matDens = 0.2},
	Ground = {matRef = 0.3, matDens = 0.2},
	Asphalt = {matRef = 0.6, matDens = 0.6},
	Salt = {matRef = 0.3, matDens = 0.5},
	Ice = {matRef = 0.7, matDens = 0.6},
	Glacier = {matRef = 0.7, matDens = 0.6},
	Glass = {matRef = 0.05, matDens = 0.6},
	ForceField = {matRef = 0.99, matDens = 0.01},
}
local dataMapping = {
	diff = function (val,val2)
		return (1-val) * (1-val2)
	end,
	dens = function (val,val2)
		return val
	end,
	decay = function (val,val2)
		return -0.3+(0.5*val)
	end,
	wet = function (val,val2)
		return -20+(30*val) + (5*(-4+val2))
	end,
	dry = function (val,val2)
		return val * 0.8
	end,
	-- functions below are still up for modification. if you have feedback or want to suggest a better function to use, lmk!
	eqHigh = function (val, val2)
		return val * val2 * -8
	end,
	eqMid = function (val, val2)
		return val * val2 * -5
	end,
	eqLow = function (val, val2)
		return val * val2 * -3
	end
}
local reverbSettings = {
	numRays = 10,
	numBounces = 2,
	calcsPerSecond = 10
}

local systemSettings = {
	debugPrintsEnabled = false,
	deciEnabled = true,
	bypassDistCheck = false,
	distCheckThreshold = 0.02 -- Lower numbers result in calculations being done out to a further distance
}

-- CRITICAL FUNCTIONS - DO NOT MODIFY --
local config = {}

function config.matCheck(mat : string)
	if materialsLibrary[mat] then
		return materialsLibrary[mat]
	else
		return materialsLibrary["Plastic"]
	end
end

function config.mapData(obj : string, val : number, val2 : number) 
	return dataMapping[obj](val, val2)
end

function config.getReverbSetting(obj : string)
	return reverbSettings[obj]
end

function config.getSysSetting(obj : string)
	return systemSettings[obj]
end
return config
