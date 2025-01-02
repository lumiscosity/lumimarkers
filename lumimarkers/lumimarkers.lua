--  __    __ __ ___  ___ __ ___  ___  ___  ____  __ __  ____ ____   __
--  ||    || || ||\\//|| || ||\\//|| // \\ || \\ || // ||    || \\ (( \
--  ||    || || || \/ || || || \/ || ||=|| ||_// ||<<  ||==  ||_//  \\
--  ||__| \\_// ||    || || ||    || || || || \\ || \\ ||___ || \\ \_))
--
--  v1.0.0 - made by lumiscosity
--  See https://github.com/lumiscosity/lumimarkers for details!
--

local Marker = require "lumimarkers/marker"
ph = require "lumimarkers/pageholder"

function pings.lm_spawnMarkerAtRaycast()
    local pos = Marker.positionFromRaycast()
    if Marker.positionIsFree(pos) then
        ph:insert(Marker:new(pos))
    end
end

lm_sync_timer = 20
lm_queue = {}

function constructSyncQueue()
    queue = {}
    for _, v in pairs(ph.markers) do
       table.insert(queue, v)
    end
    return queue
end

function events.tick()
    if not host:isHost() then
        return
    end
    lm_sync_timer = lm_sync_timer - 1
    if lm_sync_timer <= 0 then
        if #lm_queue == 0 then
            lm_queue = constructSyncQueue()
        end
        if #lm_queue == 0 then
            lm_sync_timer = 20
            return
        end

        local m = lm_queue[#lm_queue]
        if m.removed then
            lm_queue = constructSyncQueue()
            ph.reset()
            return
        end
        --log("syncing marker at id "..#lm_queue)
        --logTable(m)
        pings.lm_reconstruct(
            m.text:getText(),
            m.c,
            m.spc,
            m.marker:getPos(),
            m.marker:getScale()[2],
            m.text_anchor:getPivot()[2],
            m.marker:getRot()[2],
            m.dis_type,
            m.dis_cont,
            m.id
        )
        lm_sync_timer = 20
        table.remove(lm_queue)
    end
end

ph:reset()
action_wheel:setPage(ph.page)
