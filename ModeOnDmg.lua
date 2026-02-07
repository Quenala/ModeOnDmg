--[[

Copyright © 2026, Quenala of Asura
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of ModeOnDmg nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL QUENALA BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

]]

_addon.name = 'ModeOnDmg'
_addon.author = 'Quenala'
_addon.version = '1.0'

local texts = require('texts')
player = windower.ffxi.get_player()

------------------------------------------------
-- CONFIG
------------------------------------------------
local safe_delay = 10		-- Number of seconds to wait before going back to safe
local display_hud = true 	-- Set to false if you dont want the HUD element
local hud_X = 810			-- X Coordinate for HUD
local hud_Y = 550			-- Y Coordinate for HUD


-- Commands to send for PLD
if player.main_job == "PLD" then
	command_safe = "gs c set PhalaxMode Potency"
	command_notsafe = "gs c set PhalaxMode DT"
	
	
-- Commands to send for RUN
elseif player.main_job == "RUN" then
	command_safe = "gs c set PhalaxMode Potency"
	command_notsafe = "gs c set PhalaxMode DT"
	
	
-- Commands to send for WHM
elseif player.main_job == "WHM" then
	command_safe = "gs c set IdleMode Refresh"
	command_notsafe = "gs c set IdleMode DT"
	
	
end

------------------------------------------------
-- STATE
------------------------------------------------
local safe = true
local last_attack_time = 0
local timer_active = false

------------------------------------------------
-- HUD
------------------------------------------------
local hud = texts.new('Safe', {
    pos = {x = hud_X, y = hud_Y},
    flags = {bold = true},
    bg = {visible = false},
    padding = 4,
    textsize = 14,
    font = 'Arial',
})

if display_hud then hud:show() else hud:hide() end

------------------------------------------------
-- Helpers
------------------------------------------------
local function now()
    return os.clock()
end

local function update_hud()
    if safe then
        hud:text('     Safe')
        hud:color(0, 255, 0) -- green color for Safe-text
    else
    --    local elapsed = math.floor(now() - last_attack_time)
		local elapsed = safe_delay + last_attack_time - math.floor(now())
        hud:text(string.format('Combat %d', elapsed))
        hud:color(255, 0, 0) -- red color for Combat-text
    end
end

local function trigger_safe()
    safe = true
    timer_active = false
	if command_safe then 
		windower.send_command(command_safe)
	end
    update_hud()
end

local function register_attack()
    last_attack_time = now()

    if safe then
        safe = false
		if command_notsafe then 
			windower.send_command(command_notsafe)
		end
		timer_active = true
    end

    update_hud()
end

------------------------------------------------
-- Action event
------------------------------------------------
windower.register_event('action', function(act)
	player = windower.ffxi.get_player()
    if not player then return end

    local my_id = player.id

    for _, target in pairs(act.targets or {}) do
        if target.id == my_id then
            if act.category  == 1 or act.category  == 2 or act.category  == 3 then
				register_attack()
				return
			end	
        end
    end
end)

------------------------------------------------
-- Timer check
------------------------------------------------
windower.register_event('prerender', function()
    if not timer_active or safe then return end

    if (now() - last_attack_time) >= safe_delay then
        trigger_safe()
    else
        update_hud()
    end
end)

------------------------------------------------
-- Initial HUD state
------------------------------------------------
update_hud()
