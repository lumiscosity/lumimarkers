--  __    __ __ ___  ___ __ ___  ___  ___  ____  __ __  ____ ____   __
--  ||    || || ||\\//|| || ||\\//|| // \\ || \\ || // ||    || \\ (( \
--  ||    || || || \/ || || || \/ || ||=|| ||_// ||<<  ||==  ||_//  \\
--  ||__| \\_// ||    || || ||    || || || || \\ || \\ ||___ || \\ \_))
--
--  v1.0.0 - made by lumiscosity
--  See https://github.com/lumiscosity/lumimarkers for details!
--

local Marker = require "lumimarkers/marker"
local mainPage = require "lumimarkers/pageholder"

function pings.lm_spawnMarkerAtRaycast()
    local pos = Marker.positionFromRaycast()
    if Marker.positionIsFree(pos) then
        mainPage:insert(Marker:new(pos))
    end
end

mainPage:reset()
action_wheel:setPage(mainPage.page)
