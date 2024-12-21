local Marker = require "lumimarkers/marker"
-- mainPage is imported from Marker
marker_base = models.lumimarkers.marker.Marker:setLight(15, 15):setVisible(false)
animations["lumimarkers.anchor"].idle:play():setSpeed(0.3)
anchor = models.lumimarkers.anchor.World
-- {function (lambda)}
chat_consumer = nil

function spawnMarkerAtRaycast()
    local pos = Marker.positionFromRaycast()
    if Marker.positionIsFree(pos) then
        mainPage:insert(Marker:new(pos))
    end
end

function events.chat_send_message(msg)
    if chat_consumer then
        chat_consumer(msg)
        chat_consumer = nil
        return nil
    else
        return msg
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
