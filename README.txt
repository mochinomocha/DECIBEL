 ________  _______   ________  ___  ________  _______   ___          
|\   ___ \|\  ___ \ |\   ____\|\  \|\   __  \|\  ___ \ |\  \         
\ \  \_|\ \ \   __/|\ \  \___|\ \  \ \  \|\ /\ \   __/|\ \  \        
 \ \  \ \\ \ \  \_|/_\ \  \    \ \  \ \   __  \ \  \_|/_\ \  \       
  \ \  \_\\ \ \  \_|\ \ \  \____\ \  \ \  \|\  \ \  \_|\ \ \  \____  
   \ \_______\ \_______\ \_______\ \__\ \_______\ \_______\ \_______\
    \|_______|\|_______|\|_______|\|__|\|_______|\|_______|\|_______|
    
	Instructional Handbook for the DECIBEL system
	Version 1.01.00 - Minor Patch 1
 ----------------------------------------------------------------
			 INSTRUCTIONS
 ----------------------------------------------------------------
 1. Import the template sound object into your game. 
    This template shows exactly how the sound object should be set up for DECI to recognize it.
 2. Tag all sound sources for DECIBEL "AZERO_DECI_SOURCE", and turn on / off reverb in the object Attributes.
 3. Tag all objects for DECIBEL to interact with as "AZERO_DECI_OBJECT", no other action is needed.
 4. Place DeciLocal.lua into StarterPlayerScripts.
 5. Place the DECISRVR RBXM into ServerScriptService
 6. Place the ABSZERO RBXM into ReplicatedStorage.
 (OPTIONAL): Set up custom configuration file values.
 

You're all set! 
I'm not sure what exactly you would need for a full implementation, however this should work for most intents.
If you want a feature not shown here, or if you find a bug please lmk through a Discord DM! (@mochinomocha)
Yes, I know the setup sucks. I'll fix it in a later version, sorry.

Thanks for trying out DECI! 
It's been a long 3 years of development to get here and I'm so glad you decided to give it a shot!

- Mocha
