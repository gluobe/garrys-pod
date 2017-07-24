local M = {}
node = {}
	
fetchNodes = function(KUBERURL)
	--[[ Fetches the Node API and returns the data ]]
	http.Fetch( "http://"..KUBERURL.."/api/v1/nodes",
        function(body, len, headers, code)
			if httpConnected(body, len, headers, code) then
				bBody = body
            end
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
		else 
			return true
        end
	end
	return bBody
end

function fenceSpawn(KUBERURL)
	--[[ Tables will be used to generate a square with 8 blocks ]]
	local rangeTableX = {-200,0,200,0,-200,-200,200,200}
	local rangeTableY = {0,200,0,-200,200,-200,200,-200}
	local URL = KUBERURL
	--[[ Node inlezen en tabel beginnen printen ]]

	
	--[[ Fetches the amount of nodes from nodes.lua ]]
		nodeBody = fetchNodes(URL)
	--[[ Fill up table with API data ]]	
		
		local apiTable = util.JSONToTable(nodeBody)
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

function returnTable()
	return node

return M