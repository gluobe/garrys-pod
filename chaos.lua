--[[ Kubernetes URL, this one is used through kubectl proxy ]]
KUBERURL = "localhost:8001"

teams = {}
--[[ Holds the npc model data ]]
model = {}
--[[ The model and versions that are checked ]]
model[1] = {}
model[1]["model"] = "npc_citizen"
model[1]["version"] = "v1"
model[2] = {}
model[2]["model"] = "npc_eli"
model[2]["version"] = "v2"
model[3] = {}
model[3]["model"] = "npc_kleiner"
model[3]["version"] = "v3"

--[[ Different teams doesn't really do anything but you need it as a label on your deployment ]]
teams["green"] = {}
teams["red"] = {}
teams["purple"] = {}
teams["ebony"] = {}
teams["magenta"] = {}
teams["ivory"] = {}
enemy_npc = "npc_zombie"

--[[ Are used to send data strings to the GUI to update the node-information ]]
util.AddNetworkString("NodeMessage")
util.AddNetworkString("breakHUD")

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
    	end,
		{"Cache-Control", "no-cache"}
    )
    httpFailed = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnected = function(pbody, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from pods API")
            return
        end
		
		podsTable = util.JSONToTable(pbody)
		podsTable = podsTable['items']
		
		--[[ Amount of pods ]]
		local numberP = table.Count(podsTable)
		
		--[[ Will iterate through all existing containers ]]
		for i=1, numberP do 
			contTable = podsTable[i]
			serName = contTable['metadata']['name']
			teamName = contTable['metadata']['labels']['team']
			typeName = contTable['metadata']['labels']['type']
			imageV = contTable['spec']['containers'][1]['image']
			if contTable['status']['conditions'][2] != nil then
				phase = contTable['status']['conditions'][2]['status']
			end
			nodeName = contTable['spec']['nodeName']

			--[[ Will dissect the tag part from the imagename. This will be used to decide the model ]]
			local version = {}
			for word in imageV:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			imageV = version[2]
		
			--[[ Checks if the container has a running phase and then starts spawning models ]]
			if phase == "True" then
				local n = entitiesSpawned(serName)
				if n < 1 then 
					
					print("[Kubernetes] service "..serName.." of team "..teamName)
					blazeSpawn(serName, teamName, typeName, imageV, nodeName)
					
				end
			end	
		end
		doubleEnts(podsTable)
	end
	
	--[[ Will check if a model spawns double ]]
	function doubleEnts(testTable)
	
		--[[ Get all entities on the server and make a table with the unique ones if they have a NPC model ]]
		podEntt = ents.GetAll()
		filtClt = {}
		for i=1, table.Count(podEntt) do
			for j=1, table.Count(model) do
				if podEntt[i]:GetClass() == model[j]["model"] then
					table.insert(filtClt, podEntt[i])
				end
			end
		end
		local hasha = {}
		local ress = {}
		for _,v in ipairs(filtClt) do
		   if (not hasha[v]) then
			   ress[#ress+1] = v
			   hasha[v] = true
		   end
		end
		
		--[[ Checks the names and makes a new table out of the ones that are matched 
			It will be made into a new table that only holds the unique values.]]
		checkNames = {}
		if table.Count(ress) > table.Count(testTable) then
			for i=1, table.Count(ress) do
				for j=1, table.Count(testTable) do
					if ress[i]:GetName() == testTable[j]["metadata"]["name"] then
						table.insert(checkNames, ress[i])
					end
				end
			end
			local chhash = {}
			local chres = {}
			for _,v in ipairs(checkNames) do
			   if (not chhash[v]) then
				   chres[#chres+1] = v
				   chhash[v] = true
			   end
			end
			result = difference(ress, chres)
			if result != nil then
				for k,v in pairs(result) do
					result[k]:Remove()
				end
			end
		end	
	end
	
	--[[ Will check the differences between two tables and return it ]]
	function difference(a, b)
		local ai = {}
		local r = {}
		for k,v in pairs(a) do 
			r[k] = v; ai[v]=true 
		end
		for k,v in pairs(b) do 
			if ai[v]~=nil then   
				r[k] = nil   
			end
		end
		return r
	end
	
	--[[ USES DEPLOYMENT API TO CHECK FOR DOUBLE MODELS AND CONTAINERS ]]
	http.Fetch( "http://"..KUBERURL.."/apis/apps/v1beta1/namespaces/default/deployments",
        function(debody, len, headers, code)
			httpConnectedDeps(debody, len, headers, code)
    	end,
    	function(error)
            httpFailedDeps(error)
    	end
    )
    httpFailedDeps = function(error)
        PrintMessage(HUD_PRINTTALK, "Connection failed, something bad happened:")
        PrintMessage(HUD_PRINTTALK, error)
    end
    httpConnectedDeps = function(debody, len, headers, code)
        if code != 200 then
            PrintMessage(HUD_PRINTTALK, "Received incorrect reply from nodes API")
            return
        end
		depsTable = util.JSONToTable(debody)
		depsTable = depsTable['items']
		depsCount = table.Count(depsTable)
		
		for i=1, depsCount do
			--[[ This is done because something the tables are buggy ]]
			deps2Table = depsTable[i]
			depsName = deps2Table['metadata']['name']
			betweenTable = deps2Table['spec']['template']['spec']['containers']
			depsImage = betweenTable[1]['image']
			
			--[[ Same function as with pods ]]
			local version = {}
			for word in depsImage:gmatch("([^:]+)") do 
				table.insert(version, word)
			end
			depsImage = version[2]
			checkEntities(depsName, depsImage)
		end
	end
	
	--[[ 
		Is used to check the entities if they are using the correct model 
		This will make sure that rolling updates are automatically updated
		]]
	function checkEntities(deploymentN, im)
		podEnt = ents.GetAll()
		filtCl = {}
		for i=1, table.Count(podEnt) do
			for j=1, table.Count(model) do
				if podEnt[i]:GetClass() == model[j]["model"] then
					table.insert(filtCl, podEnt[i])
				end
			end
		end
		local hash = {}
		local res = {}
		for _,v in ipairs(filtCl) do
		   if (not hash[v]) then
			   res[#res+1] = v
			   hash[v] = true
		   end
		end
		--[[ Will compare a containername to a deploymentname & checks if the containernpc has the right model ]]
		for i=1, table.Count(res) do
			local stringMatch = {}
			local containerName = res[i]:GetName()
			--[[ splits containername so it can be matched to a deployment ]]
			for word in containerName:gmatch("([^-]+)") do 
				table.insert(stringMatch, word)
			end
			--[[ modelcheck happens here ]]
			if stringMatch[1] == deploymentN then
				local modelMatch = {}
				for j=1, table.Count(model) do
					if model[j]["version"] == im then
						table.insert(modelMatch, model[j]["model"])
					end
				end
				if res[i]:GetClass() != modelMatch[1] then
					res[i]:Remove()
				end
			end
		end
	end
	
	--[[ This makes it possible to start showing node info ]]
   --[[
     * Returns the count of all NPCs spawned for this service.
     ]]
	 
    entitiesSpawned = function(podName)
        if not podName then
            return 10000000
		end
		return table.Count(ents.FindByName(podName))
    end
	
	--[[ Checks if a table is empty or not ]]
	function is_empty(t)
		for _,_ in pairs(t) do
			return false
		end
		return true
	end
	
	
	
    --[[
     * Does the actual spawn of a NPC/entity.
     ]]
    blazeSpawn = function(what, team, type, version, nodeid)
        if not teams[team] then
            return
        end
		--[[ Checks for different image version and provides a different model1
			 Used for rolling updates.
			]]
		local e
		for i=1, table.Count(model) do
			if version == "v"..i then
				e = model[i]["model"]
				break
			else
				e = model[1]["model"]
			end
		end
		
		--[[ Decides the spawn of the model with the node location ]]
		nodeC = table.Count(node)
		for i=1, nodeC do
			if nodeid == node[i]["name"] then
				xX = node[i]["x"]
				yY = node[i]["y"]
				rangeX = rangeTableX[3] - 50
				rangeY = rangeTableY[2] - 50
			end
		end
        PrintMessage(HUD_PRINTTALK, "Spawning for service "..what)
		--[[ Create entity and spawn it ]]
        ent = ents.Create(e)
        ent:SetName(what)
		local zZ = -12700
        ent:SetPos(Vector(math.random(xX-rangeX,xX+rangeX),math.random(yY-rangeY,yY+rangeY),zZ))
        ent:Spawn()
        ent:Activate()
        ent:DropToFloor()
		
		--[[ Entity settings ]]
		ent:AddRelationship(enemy_npc.." D_HT 99")
		ent:AddRelationship(enemy_npc.." D_FR 0")
		ent:CapabilitiesRemove(CAP_MOVE_GROUND)
		ent:SetMaxHealth(50)
		ent:SetHealth(50)
        ent:SetMovementActivity(ACT_IDLE)
        ent:SetSchedule(SCHED_IDLE_STAND)
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

--[[ Creates the zombiemodel ]]
function Zombies()
	blazeSpawnKiller = function()
        local e = enemy_npc
        local entZ = ents.Create(e)
        entZ:SetName("none")
		
		rNum = math.random(1,table.Count(node))
		rangeX = rangeTableX[3] - 50
		rangeY = rangeTableY[2] - 50
		xZ = node[rNum]["x"]
		yZ = node[rNum]["y"]
		
        entZ:SetPos(Vector(math.random(xZ-rangeX,xZ+rangeX), math.random(yZ-rangeY,yZ+rangeY), -12700))
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

--[[ Starts the spawn of the zombies ]]
hook.Add( "PlayerSay", "SpawnZombies", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	timer.Create("Zombies()", 5 ,0 , Zombies)
	timer.Pause("Zombies()")
	if ( text == "spawnzombies" ) then
		timer.Start("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Start Spawning Zombies")
	else
		timer.Stop("Zombies()")
		PrintMessage(HUD_PRINTTALK, "Stop Spawning Zombies")
	end
end )

--[[ Destroys all zombie entities ]]
hook.Add( "PlayerSay", "DespawnZombies", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( text == "destroyzombies" ) then
		podEnttr = ents.GetAll()
		zombieTable = {}
		for i=1, table.Count(podEnttr) do
			if podEnttr[i]:GetClass() == enemy_npc then
				podEnttr[i]:Remove()
			end
		end
	end
end )

--[[ Takes care of the spawning of nodes 
	 This happens through the creation of range tables and
	 .....]]
function fenceSpawn()
	--[[ Tables will be used to generate a square with 8 blocks ]]
	
	--[[ Read Node API ]]
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
		
		--[[ Gather all node data necessary ]]
		for i=1, table.Count(apiTable) do
			local metaTable = apiTable[i]
			node[i] = {}
			node[i]["name"] = metaTable["metadata"]["name"]
			local memory = {}
			local mem = metaTable["status"]["capacity"]["memory"]
			local cores = metaTable["status"]["capacity"]["cpu"]
			node[i]["memory"] = mem
			node[i]["cores"] = cores
			
			--[[ Used to calculate the size of node depending on the amount of memory ]]
			for word in mem:gmatch("([^a-zA-Z]+)") do 
				table.insert(memory, word)
			end
			node[i]["calcmemory"] = tonumber(memory[1])/3000000
			
			--[[x, y and z start values ]]
			node[i]["y"] = 2000
			if i == 1 then
				node[i]["x"] = -1000
			else
				local memX = 900 * node[i]["calcmemory"]
				local calcX = node[i-1]["x"] + memX
				node[i]["x"] = calcX
			end
			node[i]["z"] = -12700
		end
	--[[ Counts the amount of nodes ]]
		for n=1, table.Count(node) do
			local z = node[n]["z"]
			--[[ the rangetables indicate the range from the center of the node to the sides ]]
			rangeTableX = {-200,0,200,0,-200,-200,200,200}
			rangeTableY = {0,200,0,-200,200,-200,200,-200}
			node[n]["xRangeTable"] = {}
			node[n]["yRangeTable"] = {}
			--[[ Loops through the amount of ranges ]]
			for i=1, table.Count(rangeTableX) do
				rangeTableX[i] = rangeTableX[i] * node[n]["calcmemory"]
				rangeTableY[i] = rangeTableY[i] * node[n]["calcmemory"]
				node[n]["xRangeTable"][i] = rangeTableX[i]
				node[n]["yRangeTable"][i] = rangeTableY[i]
				xS = node[n]["x"] + (rangeTableX[i])
				yS = node[n]["y"] + (rangeTableY[i])
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
end

--[[ Will spawn a GUI with node-info when the player enters a node area ]]
function giveNodeInfo()
	if podsTable != nil then
		ert = ents.GetAll()
		--[[ Finds player entity ]]
		for i=1, table.Count(ert) do
			if ert[i]:GetClass() == "player" then
				plyr = ert[i]
			end
		end
		--[[ Create an area with two vectors ]]
		for i=1, table.Count(node) do
			local pos1 = Vector(node[i]["x"]-node[i]["xRangeTable"][3],node[i]["y"]-node[i]["yRangeTable"][2],-12000.968750)
			local pos2 = Vector(node[i]["x"]+node[i]["xRangeTable"][3],node[i]["y"]+node[i]["yRangeTable"][2],-12799.968750)
			netTable = {}
			OrderVectors(pos1,pos2)
			checkT = plyr:GetPos():WithinAABox(pos1,pos2)
			--[[ Check if player is inside the created area ]]
			if plyr:GetPos():WithinAABox(pos1,pos2) then
				netTable["node"] = node[i]["name"]
				netTable["mem"] = node[i]["memory"]
				netTable["cores"] = node[i]["cores"]
				number = 1
				netTable["pods"] = {}
				for n=1, table.Count(podsTable) do
					if podsTable[n]['spec']['nodeName'] == node[i]["name"] then
						
						netTable["pods"][number] = podsTable[n]["metadata"]["name"]
						number = number + 1
					end
				end
				net.Start("NodeMessage")
				net.WriteTable(netTable)
				net.Send(plyr)
				break
			else
				--[[ If player is outside of area GUI will dissappear ]]
				netTable["node"] = "error"
				net.Start("NodeMessage")
				net.WriteTable(netTable)
				net.Send(plyr)
			end
		end
	end
end

function setSpawn()
	ert = ents.GetAll()
	for i=1, table.Count(ert) do
		if ert[i]:GetClass() == "player" then
			plyrs = ert[i]
		end
	end
	plyrs:SetPos(Vector(277.619232, 994.124634, -12223.968750))
end

setSpawn()
fenceSpawn()
timer.Create("Main()", 3, 0, Main)
timer.Create("nodeInfo()", 3, 0,giveNodeInfo)

