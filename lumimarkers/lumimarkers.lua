local Marker = require "lumimarkers/marker"
local mainPage = require "lumimarkers/pageholder"

function spawnMarkerAtRaycast()
    local pos = Marker.positionFromRaycast()
    if Marker.positionIsFree(pos) then
        mainPage:insert(Marker:new(pos))
    end
end

function events.mouse_press(button, action, modifier)
    if button == 1 and action == 1 then
        local eyePos = player:getPos() + vec(0, player:getEyeHeight(), 0)
        local eyeEnd = eyePos + (player:getLookDir() * 20)
        local hitLocation = { { vec(0, 0, 0), vec(1, 1, 1) } } -- this is the block location of 0,0,0 in the world
        local aabb, hitPos, side, aabbHitIndex = raycast:aabb(eyePos, eyeEnd, hitLocation)
    end
end

mainPage:reset()
action_wheel:setPage(mainPage.page)
