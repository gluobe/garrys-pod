# Garry's Pod

## Warning
**This is a demo application**.

This means that it doesn't work in every situation and contains errors when it's not used how it's supposed to be used.  If you notice that something is broken, please open an issue or, even better, open a PR with the solution.

### Known bugs:

- If too many pods die at the same time some script errors will occur and multiple models will spawn. (Don't spawn too many enemies)
- If too many pods are on a server the GUI doesn't scale with the amount of pods 

## Requirements
- Garry's Mod
	- Steam Account
	- [Buy here](http://store.steampowered.com/app/4000/Garrys_Mod/)
- Kubernetes cluster
	- Can be a [minikube](https://github.com/kubernetes/minikube) instance
	- Needs localhost:8001 access to Kubernetes API through `kubectl proxy`
	- This code is tested on a 1.9.7 cluster

## Setup
1. Make sure your cluster is running and you're able to connect to it with `kubectl proxy`.
	1. There needs to be an active API connection. 
	2. You can test this by connecting to the GUI through the [browser](http://localhost:8001/ui)
2. Install the customizations into Garry's Mod 
	1. Search for your Garry's Mod folder in your filesystem.
		1. On Windows this is default under `C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod`
		2. On MacOS this is default under `/Users/<USERNAME>/Library/Application Support/Steam/steamapps/common/GarrysMod/garrysmod`
	2. In this folder should be a Lua map.
	3. Drop **chaos.lua** in `lua/` folder
	4. Drop **gui.lua** in `lua/autorun/client` folder
3. Open up Garry's Mod and start a new singleplayer game. 
	1. The coordinates in this demo are designed for the map **gm_flatgrass**
	2. Open up the console and type `lua_openscript chaos.lua`
		1. Default the console is the button under the escape key.
4. Press **Q** and at the top of your screen an NPC menu should appear. Click it and disable **Join Player Squad**.


## Explanation
#### Nodes
If you completed these steps the game should've spawned you on top of a building looking towards some pillars.

These pillars symbolize a **node**. 

The size of each area is dependend on the amount of memory present in the node.

#### Models
Models will spawn in the node area's. The model is dependent on the image tag. 

These image tags need to be either

* v1 --> npc_citizen
* v2 --> npc_kleiner
	
Otherwise it will default to the v1 model. Each model = specific pod.

#### Bugs
By pressing `Y` the chat window should appear, type `SpawnBugs` and "bugs" will start spawning in random nodes.
By pressing `Y` again and typing `StopSpawnBugs`, the "bugs" will stop spawning but existing "bugs" will not disappear.
By pressing `Y` again and typing `DespawnBugs`, the "bugs" will stop spawning and all existing "bugs" will disappear.

### Timer
The containers will spawn on a **3** second timer. So updates **aren't instant**.

### Reset
You can either reset the state of the map by restarting the map or using the console.

- Restarting the map
	- Press `ESC` and click start new game.
	- Select the same map and everything should reload
- Console
	- Default the console is the button under the escape key.
	- type `gmod_admin_cleanup` and the map should reset.