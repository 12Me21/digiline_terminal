-- Input/output console
-- Single line input
-- Recieved text is added to the start of the output field (so, newest text is at the top)
-- (There is no way to set the default scroll position of a textarea)
-- line breaks are added automatically at the end of each message.
-- "\f" (form feed) clears the output

local function update_formspec(meta)
	local swap = meta:get_int("swap")
	meta:set_string("formspec",
		"size[6,6.5]"..
		default.gui_bg_img..
		"bgcolor[#00000000;false]"..
		"field[0.5,0.5;4,1;input;Input:;]"..
		"button[4.75,0.25;1,1;clear;CLS]"..
		"tooltip[clear;Clear Output]"..
		"textarea[0.5,1.5;5.5,4;output;Output: (top = new);"..
		minetest.formspec_escape(meta:get_string("output"))..
		"]"..
		"field_close_on_enter[input;false]"..
		-- this is added/removed so that the formspec will update every time
		(swap > 0 and " " or "")..
		
		"field[0.5,6;2.5,1;send_channel;Digiline Send Channel:;${send_channel}]"..
		"field[3.5,6;2.5,1;recv_channel;Digiline Receive Channel:;${recv_channel}]"
	)
	meta:set_int("swap", 1 - swap)
end

local terminal_rules = {
	{x= 0, y=-1, z= 0}, -- down
	{x= 1, y= 0, z= 0}, -- sideways
	{x=-1 ,y= 0, z= 0}, --
	{x= 0, y= 0, z= 1}, --
	{x= 0, y= 0, z=-1}, --
	{x= 1, y=-1, z= 0}, -- sideways + down
	{x=-1 ,y=-1, z= 0}, --
	{x= 0, y=-1, z= 1}, --
	{x= 0, y=-1, z=-1}, --
}

minetest.register_node("digiline_terminal:terminal", {
	description = "Digiline Terminal",
	groups = {choppy = 3, dig_immediate = 2},
	sounds = default and default.node_sound_stone_defaults(),
	is_ground_content = false,
	
	paramtype = "light",
	-- Maybe use this just to make all faces recieve the same light level, then slightly darken some faces of the texture.
	--light_source = 1,
	paramtype2 = "facedir",
	drawtype = "mesh",
	mesh = "digiline_terminal.obj",
	tiles = {{name = "digiline_terminal.png", backface_culling = true}},
	
	selection_box = {
		type = "fixed",
		fixed = {
			{-7/16, -8/16, -7/16, 7/16,-6.5/16, -1/16}, -- Keyboard
			{-6/16, -8/16,  0/16, 6/16,   3/16,  8/16}, -- Monitor
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-7/16, -8/16, -7/16, 7/16,-6.5/16, -1/16}, -- Keyboard
			{-6/16, -8/16,  0/16, 6/16,   3/16,  8/16}, -- Monitor
		}
	},
	
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext","Digiline Terminal")
		update_formspec(meta)
	end,
	
	digiline = {
		receptor = {
			rules = terminal_rules,
		},
		effector = {
			rules = terminal_rules,
			action = function(pos, _, channel, message)
				local meta = minetest.get_meta(pos)
				if channel == meta:get_string("recv_channel") then
					message = digiline_terminal.to_string(message)
					-- Form feed = clear screen
					-- (Only checking at the start of the message)
					if message:sub(1,1) == "\f" then
						message = message:sub(2)
					else
						message = message.."\n"..meta:get_string("output")
					end
					meta:set_string("output", message:sub(1,1000))
					update_formspec(meta)
				end
			end,
		},
	},
	on_receive_fields = function(pos, _, fields, sender)
		-- Check permission
		if digiline_terminal.protect_formspec(pos, sender, fields) then return end
		
		local meta = minetest.get_meta(pos)
		
		-- Set channels
		digiline_terminal.field(fields, meta, "send_channel")
		digiline_terminal.field(fields, meta, "recv_channel")
		
		-- CLS button
		if fields.clear then
			meta:set_string("output", "")
			update_formspec(meta)
		end
		
		-- Input submitted
		if fields.key_enter_field == "input" then
			digilines.receptor_send(pos, terminal_rules, fields.send_channel, fields.input)
			meta:set_string("input", "")
			update_formspec(meta)
		end
	end,
})