titlescreen = {}

-- Configuration


-- Path: a list of points the title should show
-- the title screen will start at [0]
titlescreen.path = {
	[0] = {x=10,y=20,z=0},
	[1] = {x=0,y=20,z=10},
	[2] = {x=-10,y=20,z=0},
	[3] = {x=0,y=20,z=-10},
}

-- The camera speed (something between 1 and 10 should do it)
titlescreen.camera_speed = 2.5


-- todo list:

--- Start at a random point from path
--- Make use of find_path (?)
--- Teleport the player to where he was before showing the title screen
--- Read the path from an external file, and camera speed from a setting
--- Make an in-game path editor (at least, a command)
--- Add a dummy logo (minetest's logo ? :p)
--- Don't allow player to interact when he's on title (revoke interact?)
--- Make him invincible and invisible (so other players don't see him floating, and can't kill him)

-- now the real mod

titlescreen.hide_hud = function(player)
	player:hud_set_flags({hotbar=false, healthbar=false, crosshair=false, wielditem=false})
end
titlescreen.show_hud = function(player)
	player:hud_set_flags({hotbar=true, healthbar=true, crosshair=true, wielditem=true})
end

titlescreen.show_title = function(player)
	local pn = player:get_player_name()
	if titlescreen.is_title[pn] then titlescreen.hide_title(player) end
	titlescreen.hide_hud(player)
	titlescreen.hud.logo[pn] = player:hud_add({
		hud_elem_type = "image",
		name = "titlescreen:logo",
		position = {x=0.5,y=0.25},
		scale = {x=1,y=1},
		text = "titlescreen_logo.png",
		alignment = {x=0,y=0},
		offset = {x=0,y=0},
	})
	titlescreen.hud.text[pn] = player:hud_add({
		hud_elem_type = "text",
		name = "titlescreen:text",
		position = {x=0.5,y=0.5},
		scale = {x=1,y=1},
		text = "Press Sneak+Jump to start",
		alignment = {x=0,y=0},
		number = 0xFFFFFF,
	})
	local e = minetest.add_entity(titlescreen.path[0],"titlescreen:camera")
	e:get_luaentity().owner = pn
	player:set_attach(e, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
	e:setvelocity({x=0,y=-1,z=0})
	titlescreen.is_title[pn] = true
end

titlescreen.hide_title = function(player)
	local pn = player:get_player_name()
	titlescreen.show_hud(player)
	player:hud_remove(titlescreen.hud.text[pn])
	player:hud_remove(titlescreen.hud.logo[pn])
	player:set_detach()
	titlescreen.is_title[pn] = false
end

minetest.register_entity("titlescreen:camera",{
	physical = false,
	collisionbox = {0,0,0,0,0,0},
	visual = "sprite",
	visual_size = {x=0,y=0},
	textures = {"titlescreen_invisible.png"},
	point_index = 0,
	on_step = function(self, dtime)
		if not self.owner then
			-- let 5 seconds to set the owner, else, it's a dead entity
			minetest.after(5, function(...)
				if not self.owner then
					self.object:remove()
				end
			end)
			return
		end
		local point = titlescreen.path[self.point_index]
		local pos = self.object:getpos()
		if math.floor(pos.x+.5) == math.floor(point.x+.5) and
		   math.floor(pos.y+.5) == math.floor(point.y+.5) and
		   math.floor(pos.z+.5) == math.floor(point.z+.5) then
			self.point_index = self.point_index+1
			if titlescreen.path[self.point_index] == nil then
				self.point_index = 0 -- we're done, come back to 0
			end
			point = titlescreen.path[self.point_index]
		end
		local d = {
			x = point.x - pos.x,
			y = point.y - pos.y,
			z = point.z - pos.z,
		}
		local dt = math.sqrt(d.x*d.x + d.y*d.y + d.z*d.z)
		local speed = titlescreen.camera_speed
		self.object:setvelocity({
			x = d.x/dt*speed,
			y = d.y/dt*speed,
			z = d.z/dt*speed,
		})
		local player = minetest.get_player_by_name(self.owner)
		if not player then return end
		if titlescreen.is_title[self.owner] then
			local c = player:get_player_control()
			if c.sneak and c.jump then
				titlescreen.hide_title(player)
				self.object:remove()
				return
			end
		end
	end,
})

titlescreen.hud = {}
titlescreen.hud.logo = {}
titlescreen.hud.text = {}

titlescreen.is_title = {}

minetest.register_chatcommand("title", {
	params = "",
	description = "Show title screen",
	privs = {},
	func = function(name, param)
		titlescreen.show_title(minetest.get_player_by_name(name))
	end,
})

minetest.register_on_joinplayer(function(player)
	-- FIXME @Minetest devs: join player works bad, really bad.
	minetest.after(2.5, function(...)
		titlescreen.show_title(player)
	end)
end)
