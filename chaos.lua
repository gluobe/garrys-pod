--[[ Main objective:
 Defend your containers against the zombie horde. A new zombie will spawn
every 5 seconds. Killed containers are respawned withing that same interval. ]]

MESOSURL = "localhost:8001"


teams = {}
teams["model1"] = "npc_citizen"
teams["model2"] = "npc_eli"
teams["green"] = {}
teams["green"]["vector"] = {}
teams["green"]["vector"]["x"] = 500
teams["green"]["vector"]["y"] = 500
teams["red"] = {}
teams["red"]["vector"] = {}
teams["red"]["vector"]["x"] = 500
teams["red"]["vector"]["y"] = 500
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
enemy_npc = "npc_combine_s"

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
    http.Fetch( "http://"..MESOSURL.."/apis/apps/v1beta1/namespaces/default/deployments",
        function(body, len, headers, code)
            httpConnected(body, len, headers, code)
    	end,
    	function(error)
            httpFailed(error)
    	end
    )

    httpFailed = function(error)
        PrintMessage(HUD_PRINTCONSOLE, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTCONSOLE, error)
    end

    httpConnected = function(body, len, headers, code)
        if code ~= 200 then
            PrintMessage(HUD_PRINTCONSOLE, "Received incorrect reply")
            return
        end
        
		beforeTable = util.JSONToTable(body)
		beforeTable = beforeTable['items']
		local numberD = table.Count(beforeTable)
		
		--[[ Will iterate through table to find all deployments ]]
		for i=1, numberD do
			spawnTable = beforeTable[i]
			
			--[[ Variables pulled from the created table. Easier than looping through because of the design of the API ]]
			serName = spawnTable['metadata']['name']
			teamName = spawnTable['metadata']['labels']['team']
			typeName = spawnTable['metadata']['labels']['type']
			replicas = spawnTable['spec']['replicas']
			
			--[[ Image version because of changing models ]]
			imageV = spawnTable['spec']['template']['spec']['containers'][1]['image']
			local version = {}
			for word in imageV:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			imageV = version[2]
			--[[ Creates the entities ]]
				local n = entitiesSpawned(serName)
				if n < replicas then
				print("[Kubernetes] service "..serName.." of team "..teamName)
					--[[ Spawns something per each container in this app]]
					for i=n+1,replicas,1 do
						blazeSpawn(serName, teamName, typeName, imageV)
					end
				end
		end
		--[[ end of loop ]]
    end

   --[[
     * Returns the count of all NPCs spawned for this service.
     ]]
    entitiesSpawned = function(service)
        if not service then
            return 10000000
        end
		return table.Count(ents.FindByName(service))
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
		if version ~= "v2" then
			e = teams["model1"]
		else
			e = teams["model2"]
		end
		
        PrintMessage(HUD_PRINTTALK, "Spawning for service "..what)

        ent = ents.Create(e)
        ent:SetName(what)
        local x = teams[team]["vector"]["x"]
        local y = teams[team]["vector"]["y"]
        ent:SetPos(Vector(math.random(x-300,x+200),math.random(y-300,y+200),150))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()

        --[[ not everyone gets a crowbar ]]
        if math.random(1,10) == 1 then
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
     * Kills a container that belongs to some service.
     */
	 // TODO: Change API to be Kubernetes compatible ]]
    killContainer = function(service)
		http.Fetch( "http://"..MESOSURL.."/api/v1/namespaces/default/pods",
			function(body, len, headers, code)
				httpConnected(body, len, headers, code)
			end,
			function(error)
				httpFailed(error)
			end
		)

		httpFailed = function(error)
			PrintMessage(HUD_PRINTCONSOLE, "Connection failed, something bad happened:")
			PrintMessage(HUD_PRINTCONSOLE, error)
		end

		httpConnected = function(body, len, headers, code)
        if code ~= 200 then
            PrintMessage(HUD_PRINTCONSOLE, "Received incorrect reply")
            return
        end
        
        local preTable = util.JSONToTable(body)
		preTable = preTable["items"]
		local numberC = table.Count(preTable)
		local killTable = {}
		--[[ Iterate over table and filter out the ones matching the deployment ]]
		for i=1, numberC do
			local checkService = preTable[i]['metadata']['name']
			local serviceTable = {}
			--[[ matches the first part of the container name with the servicename ]]
			for word in checkService:gmatch("([^-]+)") do
				table.insert(serviceTable, word)
			end
				if serviceTable[1] == service then
					table.insert(killTable, preTable[i])
				end
		end
		--[[ Get a random number from the amount of containers ]]
		local number = table.Count(killTable)
		local rand = math.random(number)
        for k, v in pairs(killTable) do
			if k == rand then
				doKillContainer(service, v['metadata']['name'])
			end
        end
		end
	end

    --[[
     * This sends the DELETE to Marathon.
     */
	 // TODO: Change API to be Kubernetes compatible ]]
    doKillContainer = function(service, killme)
		print("container that will be killed: "..killme)
        local url = "http://"..MESOSURL.."/api/v1/namespaces/default/pods/"..killme
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

    --[[
     * Spawns a killer
     ]]
    blazeSpawnKiller = function(what, team, type)
        local e = enemy_npc
        ent = ents.Create(e)
        ent:SetName("none")
        ent:SetPos(Vector(math.random(1,-2000), math.random(1,2000), 200))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()
        ent:NavSetWanderGoal(1000, 200)
        ent:SetMovementActivity(ACT_WALK)
        ent:SetSchedule(SCHED_FORCED_GO)
    end

    --[[blazeSpawnKiller()]]

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
        killContainer(service)
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

--[[ main() ]]
timer.Create("Main()", 10, 0, Main)
