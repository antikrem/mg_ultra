-- scripts\player.lua
-- executed regularly to update player when player is enabled
-- "this" refers to player


-- Standard player handle
if GlobalRegistar.get("player_alive") then
	g_sequentialDeadFrames = 0
	g_playerMovementUpdate()
	g_playerSpawnBullets()
	g_playerPowerUpdate()
	Player.update_a_friend_magic_circle(1)
	Player.update_a_friend_magic_circle(2)

-- Dead player handle
else
	g_sequentialDeadFrames = g_sequentialDeadFrames + 1

	local y 
		= (g_sequentialDeadFrames / PLAYER_DEAD_SCROLL) * PLAYER_DEAD_SCROLL_END_Y
		+ (1 - g_sequentialDeadFrames / PLAYER_DEAD_SCROLL) * PLAYER_DEAD_SCROLL_START_Y

	this:get_component(ComponentPosition):set_position(0, y, LAYER_PLAYER_BULLETS)

	if (PLAYER_DEAD_SCROLL < g_sequentialDeadFrames) then
		this:get_component(ComponentClampPosition):set_active(true)
		GlobalRegistar.update("player_alive", true)
	end
end