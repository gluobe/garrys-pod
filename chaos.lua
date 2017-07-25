--[[ Main objective:
 Defend your containers against the zombie horde. A new zombie will spawn
every 5 seconds. Killed containers are respawned withing that same interval. ]]

KUBERURL = "localhost:8001"

teams = {}
--[[ Holds the npc model data ]]
model = {}

model["1"] = "npc_citizen"
model["2"] = "npc_eli"
model["3"] = "npc_gman"
teams["green"] = {}
teams["green"]["vector"] = {}
teams["green"]["vector"]["x"] = 3000
teams["green"]["vector"]["y"] = -300
teams["green"]["vector"]["z"] = -12700
teams["red"] = {}
teams["red"]["vector"] = {}
teams["red"]["vector"]["x"] = 2500
teams["red"]["vector"]["y"] = -300
teams["red"]["vector"]["z"] = -12700
teams["purple"] = {}
teams["purple"]["vector"] = {}
teams["purple"]["vector"]["x"] = -2200
teams["purple"]["vector"]["y"] = -400
teams["ebony"] = {}
teams["ebony"]["vector"] = {}
teams["ebony"]["vector"]["x"] = -2100
teams["ebony"]["vector"]["y"] = 500
teams["magenta"] = {}
teams["magenta"]["vector"] = {}
teams["magenta"]["vector"]["x"] = -1700
teams["magenta"]["vector"]["y"] = 1900
teams["ivory"] = {}
teams["ivory"]["vector"] = {}
teams["ivory"]["vector"]["x"] = 0
teams["ivory"]["vector"]["y"] = -1500
enemy_npc = "npc_zombie"

--[[
 * The main loop, that shouldn't be named Main().
 ]]
function Main()
    --[[
     * Gets the list of running application from Marathon.
     */
    // TODO: rewrite this http.Fetch() too
	// TODO: Change API to be Kubernetes compatibl
  ]]
		
		--[[ Data required from the Pods API ]]
	http.Fetch( "http://"..KUBERURL.."/api/v1/namespaces/default/pods",
        function(pbody, len, headers, code)
			httpConnected(pbody, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(pbody, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		podsTable = util.JSONToTable(pbody)
		podsTable = podsTable['items']
		local numberP = table.Count(podsTable)
		
		--[[ Amount of ]]
		--[[ Will iterate through all existing containers ]]
		for i=1, numberP do 
			contTable = podsTable[i]
			serName = contTable['metadata']['name']
			teamName = contTable['metadata']['labels']['team']
			typeName = contTable['metadata']['labels']['type']
			imageV = contTable['spec']['containers'][1]['image']
			phase = contTable['status']['conditions'][2]['status']
			print(serName.." has status ".. phase)
			
			local version = {}
			for word in imageV:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			imageV = version[2]
			if phase == "True" then
				local n = entitiesSpawned(serName)
				if n < 1 then 
					print("[Kubernetes] service "..serName.." of team "..teamName)
					blazeSpawn(serName, teamName, typeName, imageV)
				end
			end
		end
	end
		--[[ Will iterate through table to find all deployments ]]
		
		
	
	
   --[[
     * Returns the count of all NPCs spawned for this service.
     ]]
	 
    entitiesSpawned = function(podName)
        if not podName then
            return 10000000
        end
		numberABS = table.Count(ents.FindByName(podName))
		print(numberABS)
		return table.Count(ents.FindByName(podName))
    end

    --[[
     * Does the actual spawn of a NPC/entity.
     ]]
    blazeSpawn = function(what, team, type, version)
        if not teams[team] then
            return
        end
		--[[ Checks for different image version and provides a different model1
			 Used for rolling updates.
			]]
		local e
		if version == "v1" then
			e = model["1"]
		elseif version == "v2" then
			e = model["2"]
		else 
			e = model["3"]
		end
        PrintMessage(HUD_PRINTTALK, "Spawning for service "..what)
		--[[ Create entity and spawn it ]]
        ent = ents.Create(e)
        ent:SetName(what)
        local x = teams[team]["vector"]["x"]
        local y = teams[team]["vector"]["y"]
		local z = teams[team]["vector"]["z"]
        ent:SetPos(Vector(math.random(x-200,x+200),math.random(y-200,y+200),z))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()

        --[[ not everyone gets a crowbar ]]
        if math.random(1,3) == 1 then
            ent:Give("ai_weapon_crowbar")
        end

        --[[ all your base are belong to team purple ]]
        if team == "purple" then
            ent:Give("ai_weapon_rpg")
        end

        --[[ everyone should hate zombies! ]]
        for _, zombie in pairs(ents.FindByClass(enemy_npc)) do
          --[[ make entity a zombie and add Hate to 99 ]]
            ent:AddRelationship(enemy_npc.." D_HT 99")
        end

        ent:NavSetWanderGoal(400, 8000)
        ent:SetMovementActivity(ACT_WALK)
        ent:SetSchedule(SCHED_FORCED_GO)
    end

    --[[
     * This sends the DELETE to Marathon.
     */
	 // TODO: Change API to be Kubernetes compatible ]]
    doKillContainer = function(killme)
		print("container that will be killed: "..killme)
        local url = "http://"..KUBERURL.."/api/v1/namespaces/default/pods/"..killme
        local data =
        {
            url = url,
            method = "DELETE",
            parameters = {},
            success = function(code, body, headers)
                if code ~= 200 then
                    print("[ERROR] failed to shoot container!")
                    return
                end
                PrintMessage(HUD_PRINTCENTER, "Container:  "..killme.."  will go down")
				PrintMessage(HUD_PRINTTALK, "Container:  "..killme.."  will go down")
            end,
            failed = function(message)
                print("[ERROR] failed")
            end
        }
        HTTP(data)
    end
end

function fetchPods()
	--[[ Fetches the Pods API and returns the data ]]
	headers = {}
	
	return pBody
end

function Zombies()
	blazeSpawnKiller = function()
        local e = enemy_npc
        local entZ = ents.Create(e)
        entZ:SetName("none")
        entZ:SetPos(Vector(math.random(3000,4000), math.random(-200,-1500), 12000))
        entZ:Spawn()
        entZ:Activate()
        entZ:DropToFloor()
        entZ:SetMovementActivity(ACT_WALK)
        entZ:SetSchedule(SCHED_FORCED_GO)
    end

    blazeSpawnKiller()
end

--[[ Do things when a NPC dies or something ]]
hook.Add("OnNPCKilled", "OnNPCKilled", function(npc, attacker, inflictor)
    local you = attacker:GetName()

    --[[ Spawn some goods when someone dies ]]
    local goodies = {
        "item_healthkit",
        "item_ammo_smg1",
        "item_ammo_ar2",
        "item_ammo_crossbow",
        "item_box_buckshot"
    }
    local goods = ents.Create(table.Random(goodies))
	goods:SetPos(npc:LocalToWorld(npc:OBBCenter()))
	goods:Spawn()

    --[[ Actually kill something on Mesos here
    // Example value of `npc`:
    //   NPC [184][npc_kleiner] --]]
    for npcid in string.gmatch(tostring(npc), "%[([%d]+)%]") do
        eid = npcid
    end
    service = tostring(npc:GetName())
    if service ~= "none" then
        doKillContainer(service)
    end

    --[[ Stuff that happens when the player inflicts death goes here ]]
    if you ~= "none" then
        local theplayer = 1
        local ply = Entity(theplayer)
        local wp = ply:GetActiveWeapon():GetClass()
        PrintMessage(HUD_PRINTTALK, you.." killed "..npc:GetName().." using "..wp)
    end
end)

--[[ headshot! ]]
hook.Add("ScaleNPCDamage", "ScaleNPCDamage", function(deadplayer, hitgroup, dmginfo)
    if (hitgroup == 0) then
        PrintMessage(HUD_PRINTTALK, "HEADSHOT!")
    end
end)

hook.Add( "PlayerSay", "SpawnZombies", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	timer.Create("Zombies()", 5 ,0 , Zombies)
	timer.Pause("Zombies()")
	print(text)
	if ( text == "spawnzombies" ) then
		timer.Start("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Start Spawning Zombies")
	else
		timer.Stop("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Stop Spawning Zombies")
	end
end )

--[[ Takes care of the spawning of nodes 
	 This happens through the creation of range tables and
	 .....]]
function fenceSpawn()
	--[[ Tables will be used to generate a square with 8 blocks ]]
	local rangeTableX = {-200,0,200,0,-200,-200,200,200}
	local rangeTableY = {0,200,0,-200,200,-200,200,-200}
	local URL = KUBERURL
	--[[ Node inlezen en tabel beginnen printen ]]
	http.Fetch( "http://"..KUBERURL.."/api/v1/nodes",
        function(body, len, headers, code)
			httpConnected(body, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(body, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		local apiTable = util.JSONToTable(body)
		node = {}
		apiTable = apiTable["items"]
		for i=1, table.Count(apiTable) do
			local metaTable = apiTable[i]["metadata"]
			node[i] = {}
			node[i]["name"] = metaTable["name"]
			node[i]["x"] = 3500
			if i == 1 then
				node[i]["y"] = -500
			else
				local calcY = node[i-1]["y"] - 800
				node[i]["y"] = calcY
			end
			node[i]["z"] = -12700
			
			--[[ Add node name in front of the area ]]
			hook.Add( "HUDPaint", "HelloThere", function()
				draw.DrawText( "TEST", "Trebuchet24" , ScrW() * 0.5, ScrH() * 0.25, 
				Color( 0,0,0, 255 ), TEXT_ALIGN_CENTER )
			end )
		end
	--[[ Counts the amount of nodes ]]
		for n=1, table.Count(node) do
			local z = node[n]["z"]
			--[[ Loops through the amount of ranges ]]
			for i=1, table.Count(rangeTableX) do
				local xS = node[n]["x"] + rangeTableX[i]
				local yS = node[n]["y"] + rangeTableY[i]
				--[[ Loops to put two blocks on top of each other ]]
				for j=1, 2 do 
					local ent = ents.Create("prop_physics")
					local vec = Vector(xS, yS, z)
					ent:SetModel("models/hunter/blocks/cube1x1x1.mdl")
					ent:SetPos(vec)
					ent:Spawn()
					ent:DropToFloor()
				--[[ ends 1-2 for ]]
				end
			--[[ ends ranges loop ]]	
			end
		end
	end
	
	--[[ Fetches the amount of nodes from nodes.lua ]]
		
		
end

--[[ Spawn the nodes area from nodes.lua file in /includes/modules ]]
fenceSpawn()
--[[ main() ]]
timer.Create("Main()", 4, 0, Main)

