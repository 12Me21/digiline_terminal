digiline_terminal = {};

-- Convert a value to a readable string
function digiline_terminal.to_string(x)
	if type(x) == "string" then 
		return x
	elseif type(x) == "table" then
		return dump(x)
	else
		return tostring(x)
	end
end

-- true = player tried to modify formspec without permission
-- false = player modified formspec with permission
-- nil = formspec exited (ESC) without changes
function digiline_terminal.protect_formspec(pos, player, fields)
	for i in pairs(fields) do
		if i ~= "quit" then
			local name = player:get_player_name()
			if minetest.is_protected(pos, name) then
				minetest.record_protection_violation(pos, name)
				return true
			end
			return false
		end
	end
end

-- Helper functions for saving formspec fields
function digiline_terminal.checkbox(fields, meta, name)
	local value = fields[name]
	if value then
		meta:set_int(name, value=="true" and 1 or 0)
	end
end
function digiline_terminal.field(fields, meta, name)
	local value = fields[name]
	if value then
		meta:set_string(name, value)
	end
end
function digiline_terminal.dropdown(fields, meta, name, options)
	local value = fields[name]
	if value then
		meta:set_int(name, options[value] or 1)
	end
end

dofile(minetest.get_modpath("digiline_terminal").."/terminal.lua")