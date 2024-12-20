local Marker = require "figuradm/marker"
local PageHolder = require "figuradm/pageholder"
marker_base = models.figuradm.marker.Marker:setLight(15, 15):setVisible(false)
animations["figuradm.anchor"].idle:play():setSpeed(0.3)
anchor = models.figuradm.anchor.World
-- {function (lambda)}
chat_consumer = nil
local mainPage = PageHolder:new()

function pings.spawnMarker(pos)
    for _, v in pairs(mainPage.markers) do
        if v.pos == pos then
            table.insert(newMarkers, v)
        end
    end
    mainPage:insert(Marker:new(pos, new_marker, mainPage))
end

function spawnMarkerAtRaycast()
    if player:isLoaded() then
        local eyePos = player:getPos() + vec(0, player:getEyeHeight(), 0)
        local eyeEnd = eyePos + (player:getLookDir() * 20)
        local block, hitPos, side = raycast:block(eyePos, eyeEnd)
        hitPos = vec(math.floor(hitPos.x) + 0.5, math.floor(hitPos.y), math.floor(hitPos.z) + 0.5)
        if side ~= "up" then
            hitPos = hitPos + vec(0, 1, 0)
        end
        pings.spawnMarker(hitPos*16)
    end
end

function events.chat_send_message(msg)
    if chat_consumer ~= nil then
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

action_wheel:setPage(mainPage.page)

local spawnAction = mainPage.page:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(spawnMarkerAtRaycast)

