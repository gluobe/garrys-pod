# Kubernetes cluster-visualization demo

## Warnings
**This is a demo application**
This means that it doesn't work in every situation and contains errors when it's not used how it's supposed to be used.

Known bugs:
* If too many pods die at the same time some script errors will occur and multiple models will spawn. (Don't spawn too many zombies)
* If too many pods are on a server the GUI doesn't scale with the amount of pods
* Longer delay in the GUI when a pod dies.

## Requirements
* Garry's Mod
..* Steam Account
..* [Buy here](http://store.steampowered.com/app/4000/Garrys_Mod/)
* Kubernetes cluster
..* Need localhost access through `kubectl proxy`
..* This code is tested on a 1.6.7 and 1.7.2 cluster

## Setup
1. Make sure your cluster is running and you're able to connect to it with `kubectl proxy`.
..1. There needs to be an API connection. 
..2. You can test this by connecting to the GUI through the [browser](http://localhost:8001/ui)
2. Search for your Garry's Mod folder in your filesystem.
..1. For Windows this is default under C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod
..2. In this folder should be a Lua map.
..3. Drop chaos.lua in /autorun/server
..4. Drop gui.lua in /autorun/client
3. Open up Garry's Mod and start a new singleplayer game. 
..1. The coordinates in this demo are designed for the map **gm_flatgrass**

## Usage
#### Nodes
If you completed these steps the game should've spawned you on top of a building looking towards some pillars.
These pillars symbolize a **node**. The size of each area is dependend on the amount of memory present in the node.

#### Models
Models will spawn in the node area's. The model is dependent on the image tag. 
These image tags need to be either:
					*v1 --> npc_citizen
					*v2 --> npc_eli
					*v3 --> npc_kleiner
Otherwise it will default to the v1 model. Each model is one specific pod.

#### Zombies
By pressing **Y** the chat window should appear. type spawnzombies here and zombies will start spawning in random nodes.
They will start killing the pods.
By pressing **Y** again and typing any other message the zombies will stop spawning. 