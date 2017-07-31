/*
 * Cheap copy/paste code to get some sort of box showing with a tiny bit of
 * information about what's going on.
 */

good_hud = { };
enemy_npc = "npc_zombie"

local function clr(color) return color.r, color.g, color.b, color.a; end

function good_hud:PaintBar(x, y, w, h, colors, value)
	self:PaintPanel(x, y, w, h, colors);
	x = x + 1; y = y + 1;
	w = w - 2; h = h - 2;
	local width = w * math.Clamp( value, 0, 1 );
	local shade = 4;
	surface.SetDrawColor( clr( colors.shade ) );
	surface.DrawRect( x, y, width, shade );
	surface.SetDrawColor( clr( colors.fill ) );
	surface.DrawRect( x, y + shade, width, h - shade );
end

function good_hud:PaintPanel( x, y, w, h, colors )
	surface.SetDrawColor( clr( colors.border ) );
	surface.DrawOutlinedRect( x, y, w, h );
	x = x + 1; y = y + 1;
	w = w - 2; h = h - 2;
	surface.SetDrawColor( clr( colors.background ) );
	surface.DrawRect( x, y, w, h );
end

function good_hud:PaintText( x, y, text, font, colors )
	surface.SetFont( font )
	surface.SetTextPos( x + 1, y + 1 )
	surface.SetTextColor( clr( colors.shadow ) )
	surface.DrawText( text )
	surface.SetTextPos( x, y )
	surface.SetTextColor( clr( colors.text ) )
	surface.DrawText( text )
end

function good_hud:TextSize(text, font)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end

local vars = {
	font = "TargetID",
	padding = 10,
	margin = 100,
	text_spacing = 2,
	bar_spacing = 5,
	bar_height = 16,
	width = 0.15
}

local colors = {
	background = {
		border = Color( 140, 31, 26, 255 ),
		background = Color( 120, 31, 26, 180 )
	},
	text = {
		shadow = Color( 0, 0, 0, 200 ),
		text = Color( 255, 255, 255, 255 )
	}
}

/*
 * Draw information about the platform etc.
 * - spawned containers
 * - spawned zombies
 */
local function HUDPaint( )
	client = client or LocalPlayer()
	if (!client:Alive()) then return; end
	local _, th = good_hud:TextSize("TEXT", vars.font)
	local i = 2
	local width = vars.width * ScrW()
	local bar_width = width - ( vars.padding * i )
	local height = ( vars.padding * i ) + ( th * i ) + ( vars.text_spacing * i ) + ( vars.bar_height * i ) + vars.bar_spacing
	local x = 5
	local y = 5
	local cx = x + vars.padding
	local cy = y + vars.padding
	good_hud:PaintPanel(x, y, width, height, colors.background)
	local by = th + vars.text_spacing
    local zombies = #ents.FindByClass(enemy_npc)
    local allnpcs = #ents.FindByClass("npc_*")
	local text = "Enemies: "..zombies
	good_hud:PaintText( cx, cy, text, vars.font, colors.text )
	local text = "Containers: "..allnpcs-zombies
	good_hud:PaintText( cx, cy + by, text, vars.font, colors.text )
end

hook.Add( "HUDPaint", "PaintOurHud", HUDPaint );

net.Receive("NodeMessage", function()
	local rTable = net.ReadTable()
	if rTable["node"] != "error" then 
		hook.Add("HUDPaint", "PaintHUD", function()	
			local varsi = {
				font = "TargetID",
				padding = 10,
				margin = 200,
				text_spacing = 2,
				bar_spacing = 5,
				bar_height = 16,
				width = 0.30
			}
			local _, th = good_hud:TextSize("TEXT", vars.font)
			local i = 5
			local width = varsi.width * ScrW()
			local bar_width = width - ( varsi.padding * i )
			local height = ( varsi.padding * i ) + ( th * i ) + ( varsi.text_spacing * i ) + ( varsi.bar_height * i ) + varsi.bar_spacing
			local xX = ScrW() / 2
			local yY = ScrH() / 2
			local cx = xX + varsi.padding
			local cy = yY + varsi.padding
			good_hud:PaintPanel(xX - (width/2), yY - (height/2), width, height, colors.background)
			local by = th + varsi.text_spacing
			good_hud:PaintText( cx - (width/2), cy - (height/2), "Nodename: ", vars.font, colors.text ) 
			local by = th + varsi.text_spacing
			local name = "\t\t"..rTable["node"] 
			good_hud:PaintText( cx - (width/2), cy + by - (height/2), name, vars.font, colors.text )
			local by = by + th + varsi.text_spacing			
			local cpu = "CPU: \t\t"..rTable["cores"]
			good_hud:PaintText( cx - (width/2), cy + by - (height/2) , cpu, vars.font, colors.text )
			local by = by + th + varsi.text_spacing	
			local mem = "Memory: \t\t"..rTable["mem"]
			good_hud:PaintText( cx - (width/2), cy + by - (height/2) , mem, vars.font, colors.text )
			local by = by + th + varsi.text_spacing
			local contai = "Pods: "
			good_hud:PaintText( cx - (width/2), cy + by - (height/2) , contai, vars.font, colors.text )
			for n=1, table.Count(rTable["pods"]) do
				by = by + th + varsi.text_spacing
				local cont = "\t\t"..rTable["pods"][n]
				good_hud:PaintText( cx - (width/2), cy + by - (height/2) , cont, vars.font, colors.text )
			end
		end)
	else
		hook.Remove( "HUDPaint", "PaintHUD" )
		return
	end
end)