-- scripts\initialise_player_system.lua

--Registar value to control
GlobalRegistar.add("player_alive", true)
GlobalRegistar.add("player_active", false)

Player = {}

-- Player movement

--Table used for gettings certain velocity values
PLAYER_MAX_VELOCITY_TABLE = {
	DEFAULT = 9.25,
	DASH = 50,
	FOCUS = 4.3
}

--Similar table for acceleration
PLAYER_MAX_ACCELERATION_TABLE = {
	DEFAULT = 1.75,
	DASH = 55,
	FOCUS = 0.5
}

-- Additional soft position clamping
PLAYER_X_CLAMP = 960
PLAYER_Y_CLAMP = 540

-- Dash related variables
PLAYER_DASH_LENGTH = 11
PLAYER_DASH_COOLDOWN = 4

-- Constants for dead player
Player.PRE_DEAD_SCROLL = 50
PLAYER_DEAD_SCROLL = 70
PLAYER_DEAD_SCROLL_START_Y = -640
PLAYER_DEAD_SCROLL_END_Y = -270

-- Max turn rate of player 
PLAYER_MAX_TURN_VELOCITY = 7;
-- Theres a mechanic called quick shift
-- If the player switches direction quickly its instant
-- This is the threshold angle to active
PLAYER_QUICK_SHIFT_THRESHOLD = 70

-- shooting timer
PLAYER_SHOOT_TIMING = 10

-- Counter for number of dead frames
Player.preDeadFrames = 0
Player.sequentialDeadFrames = 0

--Flip for player
g_playerBulletOscillator = -1

-- Values that represent the last dash direction
g_lx, g_ly = 0,0
-- Set to true when a dash is occuring
g_inDash = false
-- Set to true when focus
g_inFocus = false
-- Set to true when the dash key is released
g_dashReleased = true
-- Time spent in dash
g_dashDuration = 0
-- Time spent in cooldown
g_dashCooldown = 0

-- Tends from 0 to one when in shift
g_shiftFactor = 0
-- Shift factor change value
PLAYER_SHIFT_FACTOR_DELTA = 0.02


-- Constants for bullet friend circle position
PLAYER_FRIEND_RESTING_OFFSET = 120
PLAYER_FRIEND_FOCUS_OFFSET = 120
PLAYER_FRIEND_FOCUS_ROTATION_MULTIPLIER = 17

-- Constants for bullet targets when firing
PLAYER_FRIEND_TARGET = 550

-- Variables about health
Player.lives = 99

-- Sets godmode
Player.godmode = false

-- Players current meter
-- A bar is 100, Maxes at 300
Player.meter = 0
Player.METER_DASH_COST = 100
Player.MAX_METER = 300
Player.inShiftDash = false
Player.SHIFT_DASH_LINGER = 30

-- Total point
g_points = 0

-- Variables on fragments for new lives
FRAGMENT_PERIOD = 25
g_fragments = 0
g_nextFragments = FRAGMENT_PERIOD

-- Power of player
PLAYER_POWER_LEVEL_THRESHOLD = 20
PLAYER_POWER_LEVEL_DRAIN_FACTOR = 0.5
PLAYER_RESTING_FRAGMENT_POINTS_DRAIN = 0.5
PLAYER_FOCUS_FRAGMENT_POINTS_DRAIN = 0.1
g_power = 0
g_power_level = 0

-- Clear variables and constants
PLAYER_CLEAR_RADIUS = 250
PLAYER_CLEAR_FRAMES = 250
Player.clearOnDeath = false

-- Player magnet
Player.MAGNET_Y = 300
Player.MAGNET_RESET = 350
Player.magnet_cooldown = Player.MAGNET_RESET

-- Power bouses for certain events
Player.METER_BONUS_PICKUP = 0.5
Player.METER_BONUS_VELOCITY = 0.0005
Player.METER_BONUS_MAGNET = 2.0


--loading assets for player
Audio.request_load_file("player_shoot_tick", "shoot_click.wav")
Audio.request_load_file("player_death_sound", "old_gauge_sc_f.wav")
Audio.request_load_file("player_meter_up", "old_gauge_sc_r.wav")
Audio.flush_queue()

-- Functions used to update player during regular gameplay
g_playerMovementUpdate = function()
	--The position of the player
	local cPosition = this:get_component(ComponentPosition)
	--More sophisticated interface for controlling movement
	local cMovement = this:get_component(ComponentMovement)
	--A component to get player input
	local cInput = this:get_component(ComponentInput)

	--represents input
	local ix, iy = 0,0

	if cInput:query_down("left")  == 1 then ix = ix - 1 end
	if cInput:query_down("right") == 1 then ix = ix + 1 end
	if cInput:query_down("up")    == 1 then iy = iy + 1 end
	if cInput:query_down("down")  == 1 then iy = iy - 1 end

	local isDashInput = cInput:query_down("dash")

	local isFocusInput = cInput:query_down("focus")

	--Update dash variables
	if g_dashCooldown > 0 then g_dashCooldown = g_dashCooldown - 1 end
	if g_dashDuration > 0 then g_dashDuration = g_dashDuration - 1 end

	--if currently dashing
	if g_inDash then	
		--check for dash conditions to fail
		if ix ~= lx or iy ~= ly or g_dashDuration <= 0 then
			g_dashDuration = 0
			g_inDash = false

			if Player.inShiftDash then
				Player.deshade_shift_dash()
			end
			
			g_dashCooldown = PLAYER_DASH_COOLDOWN
		end
	end

	--check if key input will allow for dash
	if isDashInput == 1 then
		--handle case where dash input recieved out of dash 
		if not g_inDash and g_dashReleased and g_dashCooldown <= 0 then
			g_inDash = true
			lx = ix
			ly = iy

			g_dashDuration = PLAYER_DASH_LENGTH
			g_dashReleased = false;

			-- Check if this is a shift dash
			if isFocusInput == 1 then
				-- Shade player and apply shift dash
				Player.shade_shift_dash()

			end
		end
	else
		g_dashReleased = true
	end

	
	g_inFocus = isFocusInput == 1 and not g_inDash

	local movementMode = g_inDash and "DASH" or (g_inFocus and "FOCUS" or "DEFAULT")

	if g_inFocus then Player.tend_render_hitbox() else Player.tend_derender_hitbox() end

	--calculate updated movement
	local maxAcceleration = PLAYER_MAX_ACCELERATION_TABLE[movementMode]
	local maxVelocity = PLAYER_MAX_VELOCITY_TABLE[movementMode]

	--current speedVelocity and speedAngle
	local smag, cang = cMovement:get_speed(), cMovement:get_angle()
	--calculate input direction
	local tmag, tang = math.to_polar(ix, iy)

	--need to turn compute shortest turn 
	local turn = math.compute_smallest_turn(tang, cang);

	if tmag > 0.1 then
		--Theres a mechanic called quick shift
		--if the player switches direction quickly its instant
		if math.abs(turn) > PLAYER_QUICK_SHIFT_THRESHOLD then
			cMovement:set_angle(tang)
		else
			cMovement:set_angle_change(turn)
		end
	else
		cMovement:set_angle_change(0)
	end

	this:get_component(ComponentMovement):set_speed_cap(maxVelocity)

	--calculate acceleration
	--consider no input case
	if tmag < 0.1 then
		--if speed is slow, set speed and acceleration to zero
		if math.clamp(cMovement:get_speed(), 0, cMovement:get_speed()) 
				<= PLAYER_MAX_ACCELERATION_TABLE[movementMode] then
			cMovement:set_speed(0.001)
			cMovement:set_speed_change(0)
		--otherwise, slow down the player
		else 
			cMovement:set_speed_change(-PLAYER_MAX_ACCELERATION_TABLE[movementMode])
		end
	--otherwise set acceleration as expected
	else
		cMovement:set_speed_change(maxAcceleration)
	end

	if g_inDash then
		this:get_component(ComponentParticle):spawn(1)	
	end

	-- Add meter based on velocity
	local speed = cMovement:get_speed()
	if speed > 0.1 then 
		Player.add_meter(speed * Player.METER_BONUS_VELOCITY)
	end
	
	-- Modify shift factor
	g_shiftFactor = math.tend_to(g_shiftFactor, isFocusInput, PLAYER_SHIFT_FACTOR_DELTA)
end

-- spawn bullet at given layer
g_playerSpawnBullet = function(x, y, tx, ty, i)
	--The position of the player
	local cPosition = this:get_component(ComponentPosition)

	local angle = math.angle_to(x, y, tx, ty)

	local cSpawner = this:get_component(ComponentSpawner)
	cSpawner:create_entity(EntityPlayerBullets)
			
	cSpawner:add_component(ComponentPosition.create(x, y, LAYER_PLAYER_BULLETS))
	cSpawner:add_component(ComponentCollision.create(27))
	cSpawner:add_component(ComponentDamage.create(10 * (1.0 / i)))
	cSpawner:add_component(ComponentOffsetOnce.create())
	cSpawner:add_component(ComponentMinAmbient.create(0.8))
	cSpawner:add_component(ComponentRotation.create())
	cSpawner:add_component(ComponentPointLight.create(1.0, 0.75, 0.05, 0.0015, 0.07, 3.2))

	local pod = ComponentParticleOnDeath.create("death_gold_fragments_subtle")
	pod:set_velocity_range(1.0, 1.3);
	pod:set_direction_deviation(10);
	cSpawner:add_component(pod)
			
	local bulletGComponents = ComponentGraphics.create("bullet_cross")
	bulletGComponents:set_animation(1)
	bulletGComponents:set_scale(0.7)
	cSpawner:add_component(bulletGComponents)
			
	local bulletMComponent = ComponentMovement.create()
	bulletMComponent:set_speed(36)
	bulletMComponent:set_angle(angle + 2.5 * g_playerBulletOscillator)
	cSpawner:add_component(bulletMComponent)

	cSpawner:push_entity()

end


-- Standard bullet handler
g_playerSpawnBullets = function()

	--A component to look at movement
	local cInput = this:get_component(ComponentInput)

	--Timing component
	local cTiming = this:get_component(ComponentTimer)


	--create bullet entities
	if cInput:query_down("shoot") == 1 and 
			(cTiming:get_cycle() % PLAYER_SHOOT_TIMING) == 0 then

		-- Oscilate bullet position
		g_playerBulletOscillator = g_playerBulletOscillator * -1

		-- Generate target position
		local ty = math.lerp(g_shiftFactor, PLAYER_FRIEND_RESTING_OFFSET, PLAYER_FRIEND_TARGET)

		for i in range(1, g_power_level + 1) do

			-- Generate desired point
			local x, y = math.rotate_point(0, -PLAYER_FRIEND_FOCUS_OFFSET, PLAYER_FRIEND_FOCUS_ROTATION_MULTIPLIER * (i - 0.5))

			-- lerp current position to tarrget
			x = math.lerp(math.max(g_shiftFactor, 0.01), 0, x)
			y = math.lerp(math.max(g_shiftFactor, 0.01), PLAYER_FRIEND_RESTING_OFFSET, y)

			g_playerSpawnBullet(x, y, 0, ty, i)
			
			-- Generate desired point
			local x, y = math.rotate_point(0, -PLAYER_FRIEND_FOCUS_OFFSET, -PLAYER_FRIEND_FOCUS_ROTATION_MULTIPLIER * (i - 0.5))

			-- lerp current position to tarrget
			x = math.lerp(math.max(g_shiftFactor, 0.01), 0, x)
			y = math.lerp(math.max(g_shiftFactor, 0.01), PLAYER_FRIEND_RESTING_OFFSET, y)

			g_playerSpawnBullet(x, y, 0, ty, i)
		end
	end

	-- If we get a press even, play the audio source
	if cInput:query_press("shoot") == 1 then
		this:get_component(ComponentAudio):set_repeat(true)
		this:get_component(ComponentAudio):play_source()
	-- Otherwise disable repeat to stop audio naturally
	elseif cInput:query_down("shoot") == 0 then
		this:get_component(ComponentAudio):set_repeat(false)
	end

end

-- Cyclic update to modify Power
g_playerPowerUpdate = function()
	local drain = 0
	if g_inFocus then drain = PLAYER_FOCUS_FRAGMENT_POINTS_DRAIN else drain = PLAYER_RESTING_FRAGMENT_POINTS_DRAIN end
	g_power = g_power - PLAYER_POWER_LEVEL_DRAIN_FACTOR * drain * (g_power / 100) ^ 3
	g_power = math.max(0, g_power)
end

-- Creates some particles at player location
Player.meter_up_particle_burst = function()
	local x, y, z = EntityPool.get_player():get_component(ComponentPosition):get_position()
	for _ in range(0, 9) do
		local ox, oy, oz = math.sample_uniform_circle(50)
		EntityPool.get_player():get_component(ComponentMultiEntity):get("meter"):get_component(ComponentParticle):spawn_at(x + ox, y + oy, z + oz)
	end
end

-- Function to increment meter
-- Will do fancy effects on meter up
Player.add_meter = function(meter)
	if is_nil(meter) then meter = 1 end
	local oldMeter = Player.meter
	Player.meter = Player.meter + meter

	-- Check floor division
	if oldMeter // Player.METER_DASH_COST ~= Player.meter // Player.METER_DASH_COST then	
		local e = Entity.create(EntityGeneric)
		local s = ComponentTimer.create()
		s:set_spam_offset(15)
		s:add_spam_callback("Player.meter_up_particle_burst()", 4)
		s:add_callback(15, "this:kill()")
		e:add_component(s)

		EntityPool.add_entity(e)

		e = Entity.create(EntityGeneric)
		local s = ComponentTimer.create()
		s:add_callback(10, "Audio.play_once(\"player_meter_up\")")
		s:add_callback(25, "this:kill()")
		e:add_component(s)

		EntityPool.add_entity(e)

	end
end

-- Effect for when 

-- Shades player when shift dashing
Player.shade_shift_dash = function()
	if Player.meter > Player.METER_DASH_COST then
		Player.meter = Player.meter - Player.METER_DASH_COST
		Player.inShiftDash = true
		EntityPool.get_player():get_component(ComponentColourModulation):set_strength(1.0)
	end
end

-- Deshade player and set dash invinc off
Player.deshade_shift_dash = function()
	-- Done with Entity
	local e = Entity.create(EntityGeneric)
	local t = ComponentTimer.create()
	t:add_spam_callback(
		[[
			local strength = EntityPool.get_player():get_component(ComponentColourModulation):get_strength()
			strength = strength - 2.0 / Player.SHIFT_DASH_LINGER
			if strength <= 0 then
				Player.inShiftDash = false
				EntityPool.get_player():get_component(ComponentColourModulation):set_strength(0)
				this:kill()
			else
				EntityPool.get_player():get_component(ComponentColourModulation):set_strength(strength)
			end
		]],
		2
	)
	e:add_component(t)
	EntityPool.add_entity(e)
end



-- Handler function when player is hit
g_bulletPlayerCollision = function() 
	if GlobalRegistar.get("player_alive") and not Player.inShiftDash and not Player.godmode then
		Player.lives = Player.lives - 1
		this:get_component(ComponentClampPosition):set_active(false)
		Player.clearOnDeath = true
		GlobalRegistar.update("player_alive", false)

		Audio.play_once("player_death_sound")
	end
	
	-- Kill bullet
	target1:kill()
end

-- Enables the player system
Player.enable_player = function()
	GlobalRegistar.add("player_active", true)
end

-- Execute a function that treats player as this
Player.execute_against = function(f, ...)
	this = EntityPool.get_player()

	if is_nil(this) then return end

	f(...)
	this = nil
end

-- Returns player position
Player.get_position = function()
	local player = EntityPool.get_player()
	if player then return player:get_component(ComponentPosition):get_position() else return nil end
end

-- Add friend magic circle
-- Works only when this points to player
Player.add_friend_magic_circle = function(layer)
	-- Create freind magic circles
	local mc = Entity.create(EntityGeneric)

	mc:add_component(ComponentPosition.create(0, PLAYER_FRIEND_RESTING_OFFSET, 0))
	mc:add_component(ComponentGraphics.create("mc_fire_circle", 0.8))
	mc:add_component(ComponentRotation.create(0, 2))

	mc:add_component(ComponentOffsetMaster.create(true))
	mc:add_component(ComponentDieWithMaster.create())
	mc:add_component(ComponentNoBoundsControl.create())

	mc:add_component(ComponentPointLight.create(1.0, 0.75, 0.05, 0.0015, 0.07, 3.2))
	mc:add_component(ComponentMinAmbient.create(1.1))

	mc:add_component(ComponentTransparency.create(1.0, 0.005))

	mc:add_component(ComponentName.create(tostring(layer)))

	this:get_component(ComponentSpawner):add_entity(mc)

	mc = Entity.create(EntityGeneric)

	mc:add_component(ComponentPosition.create(0, PLAYER_FRIEND_RESTING_OFFSET, 0))
	mc:add_component(ComponentGraphics.create("mc_fire_circle", 0.8))
	mc:add_component(ComponentRotation.create(0, 2))

	mc:add_component(ComponentOffsetMaster.create(true))
	mc:add_component(ComponentDieWithMaster.create())
	mc:add_component(ComponentNoBoundsControl.create())

	mc:add_component(ComponentPointLight.create(1.0, 0.75, 0.05, 0.0015, 0.07, 3.2))
	mc:add_component(ComponentMinAmbient.create(1.1))

	mc:add_component(ComponentTransparency.create(1.0, 0.005))

	mc:add_component(ComponentName.create("-" .. tostring(layer)))

	this:get_component(ComponentSpawner):add_entity(mc)
end


-- Update friend magic circle
-- Works only when this points to player
Player.update_a_friend_magic_circle = function(layer)
	local offsetX, offsetY = this:get_component(ComponentPosition):get_position()


	-- Left circle
	local mc = this:get_component(ComponentMultiEntity):get("-" .. tostring(layer))

	-- Generate desired point
	local targetX, targetY = math.rotate_point(0, -PLAYER_FRIEND_FOCUS_OFFSET, PLAYER_FRIEND_FOCUS_ROTATION_MULTIPLIER * (layer - 0.5))

	-- lerp current position to tarrget
	targetX = math.lerp(g_shiftFactor, 0, targetX)
	targetY = math.lerp(g_shiftFactor, PLAYER_FRIEND_RESTING_OFFSET, targetY)

	if not is_nil(mc) then
		mc:get_component(ComponentPosition):set_position(offsetX + targetX, offsetY + targetY)
	end

	-- Right circle
	local mc = this:get_component(ComponentMultiEntity):get(tostring(layer))

	-- Generate desired point
	local targetX, targetY = math.rotate_point(0, -PLAYER_FRIEND_FOCUS_OFFSET, -PLAYER_FRIEND_FOCUS_ROTATION_MULTIPLIER * (layer - 0.5))

	-- lerp current position to tarrget
	targetX = math.lerp(g_shiftFactor, 0, targetX)
	targetY = math.lerp(g_shiftFactor, PLAYER_FRIEND_RESTING_OFFSET, targetY)

	if not is_nil(mc) then
		mc:get_component(ComponentPosition):set_position(offsetX + targetX, offsetY + targetY)
	end

end

-- Handles power up screen wide magnet
Player.player_magnet_check = function()
	local _, y = this:get_component(ComponentPosition):get_position()
	
	if y < Player.MAGNET_Y  and Player.magnet_cooldown > 0 then
		Player.magnet_cooldown = Player.magnet_cooldown - 1
	end

	if y > Player.MAGNET_Y and Player.magnet_cooldown <= 0 then
		local powerups = EntityPool.get_by_type(EntityPowerUp)

		for k, v in pairs(powerups) do
			v:execute_against(PowerUp.apply_magnet, true)
		end

		Player.magnet_cooldown = Player.MAGNET_RESET

	end
	
end

-- Removes friend circles
-- Works only when this points to player
Player.remove_a_friend_magic_circle = function(layer)

	-- Left circle
	local mc = this:get_component(ComponentMultiEntity):get("-" .. tostring(layer))

	if not is_nil(mc) then
		mc:kill()
	end

	-- Right circle
	local mc = this:get_component(ComponentMultiEntity):get(tostring(layer))

	if not is_nil(mc) then
		mc:kill()
	end

end

-- General handling for friends
Player.friend_handle = function(layer)
	requiredLevel = math.floor(g_power / PLAYER_POWER_LEVEL_THRESHOLD) + 1

	while g_power_level < requiredLevel do
		g_power_level = g_power_level + 1
		Player.add_friend_magic_circle(tostring(g_power_level))
	end

	while g_power_level > requiredLevel do
		Player.remove_a_friend_magic_circle(tostring(g_power_level))
		g_power_level = g_power_level - 1
	end

	for i in range(1, g_power_level + 1) do
		Player.update_a_friend_magic_circle(i)
	end
end

-- Add hitbox child
Player.add_hitbox = function()
	-- Create freind magic circles
	local mc = Entity.create(EntityGeneric)

	mc:add_component(ComponentPosition.create(0, 0, LAYER_PLAYER - 5))
	mc:add_component(ComponentGraphics.create("player_hitbox"))

	mc:add_component(ComponentOffsetMaster.create(true))
	mc:add_component(ComponentDieWithMaster.create())
	mc:add_component(ComponentNoBoundsControl.create())

	mc:add_component(ComponentMinAmbient.create(1))

	mc:add_component(ComponentTransparency.create(0.0, 0.005))

	mc:add_component(ComponentName.create("hitbox"))

	this:get_component(ComponentSpawner):add_entity(mc)

end

-- Add meter particle spawner
Player.add_meter_effecter = function()
	-- Create freind magic circles
	local mc = Entity.create(EntityGeneric)

	mc:add_component(ComponentPosition.create(0, 0, -1))

	mc:add_component(ComponentOffsetMaster.create(true))
	mc:add_component(ComponentDieWithMaster.create())
	mc:add_component(ComponentNoBoundsControl.create())

	mc:add_component(ComponentParticle.create("meter_up_blue_sparks"))

	mc:add_component(ComponentName.create("meter"))

	this:get_component(ComponentSpawner):add_entity(mc)

end

-- Tend hitbox towards rendering
Player.tend_render_hitbox = function()
	local hitbox = this:get_component(ComponentMultiEntity):get("hitbox")
	if is_nil(hitbox) then return end
	local trans = hitbox:get_component(ComponentTransparency)
	if trans:get_target() < 0.5 then trans:set_target(1.0) trans:set_rate(0.01) end
end

-- Tend hitbox towards rendering
Player.tend_derender_hitbox = function()
	local hitbox = this:get_component(ComponentMultiEntity):get("hitbox")
	if is_nil(hitbox) then return end
	local trans = hitbox:get_component(ComponentTransparency)
	if trans:get_target() > 0.5 then trans:set_target(0.0) trans:set_rate(0.2) end
end

-- Attaches a clearing entitity
Player.add_clear_aura = function()
	-- Create timed death emmitter
	local mc = Entity.create(EntityBulletClearer)

	mc:add_component(ComponentPosition.create(0, 0, LAYER_PLAYER))

	mc:add_component(ComponentOffsetMaster.create(true))
	mc:add_component(ComponentDieWithMaster.create())
	mc:add_component(ComponentNoBoundsControl.create())

	mc:add_component(ComponentDeathEmitter.create())
	mc:add_component(ComponentCollision.create(PLAYER_CLEAR_RADIUS))

	mc:add_component(ComponentGraphics.create("mc_elegant_circle_large"))

	mc:add_component(ComponentName.create("clearer"))

	local timer = ComponentTimer.create()
	timer:add_callback(
		PLAYER_CLEAR_FRAMES, 
		"this:kill()" 
	)

	mc:add_component(timer)

	this:get_component(ComponentSpawner):add_entity(mc)

end