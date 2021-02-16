local love = _G.love

local camera = require 'camera'
local stage = require 'stage'
local window = require 'window'

local utilities = {}

function utilities.clamp(x, min, max)
	if x < min then
		return min
	elseif x > max then
		return max
	else
		return x
	end
end

function utilities.leftEdge() -- get temp left edge based on camera and window position
	return math.max(window.left + camera.camera_xy[1], stage.left)
end

function utilities.rightEdge() -- get temp right edge based on camera and window position
	return math.min(window.right + camera.camera_xy[1], stage.right)
end

local function quadOverlap(q1, q2)
	return q1.R > q2.L and q2.R > q1.L and q1.D > q2.U and q2.D > q1.U
end

function utilities.check_got_hit(getting_hit, attacker)
	local gothit = false
	if attacker.isAttacking then
		local hurt = getting_hit.hurtboxes
		local hit = attacker.hitboxes
		for i = 1, #hurt do
			for j = 1, #hit do
				if (quadOverlap(hurt[i], hit[j])) then
					gothit = true
					local flag_list = {hurt[i].Flag1, hit[j].Flag1, hit[j].Flag2}
					for _, flag in pairs(flag_list) do
						if flag then attacker.hit_type[flag] = true end
					end
				end
			end
		end
	end

	return gothit
end

function utilities.checkVersion()
	local major, minor, revision = love.getVersion()
	local version = major * 10000 + minor * 100 + revision * 1
	local min_version = 110300
	assert(version >= min_version, "Please update your Love2D to the latest version.")
end

return utilities
