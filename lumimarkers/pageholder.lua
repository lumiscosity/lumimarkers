-- The Action Wheel pageholder style adds the following components to markers/zones:
-- action: The action used to represent this marker. The title of this action is the marker's name.
-- page: The configuration page for this marker.

lm_chatConsumer = nil
lm_preserve_consumer = false

local action_wheels = {}
local current_wheel = 1

function lm_addActionWheel(page, name)
    table.insert(action_wheels, {
        name = name,
        page = page
    })
end

local switch_key = keybinds:newKeybind("Switch action wheel", "key.keyboard.n", true)

switch_key.press = function()
    if #action_wheels > 1 then
        current_wheel = (current_wheel % #action_wheels) + 1
        action_wheel:setPage(action_wheels[current_wheel].page)
        host:setActionbar("Switched to action wheel: "..action_wheels[current_wheel].name)
    end
end

local sneak_key = keybinds:newKeybind("Sneak", keybinds:getVanillaKey("key.sneak"), true)

---A class describing the UI and marker/zone storage.
---When implementing a new UI framework, the abstract calls have to be implemented.
---Only one instance of a PageHolder exists; get it by requiring this file.
---@class PageHolder
local PageHolder = {
    markerPage = action_wheel:newPage(),
    markers = {},
    markerNext = 0,
    zonePage = action_wheel:newPage(),
    zones = {},
    zoneNext = 0
}

---Regenerates the PageHolder.
function PageHolder:reset()
    PageHolder.markerPage = action_wheel:newPage()
    PageHolder.zonePage = action_wheel:newPage()

    PageHolder.markerPage:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(function()
        pings.lm_spawnMarkerAtRaycast()
    end)
    PageHolder.markerPage:newAction()
    :title("Switch to zones")
    :item("orange_concrete")
    :onLeftClick(function()
        action_wheel:setPage(PageHolder.zonePage)
    end)

    PageHolder.zonePage:newAction()
    :title("Spawn rectangular zone")
    :item("orange_banner")
    :onLeftClick(lm_spawnRectZone)
    PageHolder.zonePage:newAction()
    :title("Spawn circular zone")
    :item("orange_dye")
    :onLeftClick(lm_spawnCircleZone)
    PageHolder.zonePage:newAction()
    :title("Switch to markers")
    :item("blue_concrete")
    :onLeftClick(function()
        action_wheel:setPage(PageHolder.markerPage)
    end)

    PageHolder.markerNext = 0
    local newMarkers = {}

    for _, v in pairs(PageHolder.markers) do
        if not v.removed then
            PageHolder.markerNext = PageHolder.markerNext + 1
            v.id = PageHolder.markerNext
            newMarkers[PageHolder.markerNext] = v
        end
    end

    PageHolder.markers = newMarkers

    for _, v in pairs(PageHolder.markers) do
        PageHolder.markerPage:setAction(-1, v.action)
    end

    PageHolder.zoneNext = 0
    local newZones = {}

    for _, v in pairs(PageHolder.zones) do
        if not v.removed then
            PageHolder.zoneNext = PageHolder.zoneNext + 1
            v.id = PageHolder.zoneNext
            newZones[PageHolder.zoneNext] = v
        end
    end

    PageHolder.zones = newZones

    for _, v in pairs(PageHolder.zones) do
        PageHolder.zonePage:setAction(-1, v.action)
    end
end

---Removes all markers/zones queued for deletion.
function PageHolder:gc()
    PageHolder:reset()
    action_wheel:setPage(PageHolder.markerPage)
end

function PageHolder.genMarkerPage(marker)
    marker.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(ph.markerPage)
            if lm_chatConsumer then
                host:setActionbar("Cancelled")
                lm_chatConsumer = nil
            end
        end)
    marker.page:newAction()
        :title("Rename")
        :item("name_tag")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                marker.action:title(x)
                pings.lm_setName(x, marker.id)
                host:setActionbar("Set marker name to " .. x)
            end
            host:setActionbar("Type the new name in chat, or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Change icon")
        :item("item_frame")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                if not pcall(world.newItem, x) then
                    host:setActionbar("Invalid item!")
                    return
                end
                marker.action:item(x)
                host:setActionbar("Set icon to " .. x)
            end
            host:setActionbar("Type the item ID for the new icon in chat, or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Set color")
        :item("white_dye")
        :onLeftClick(function()
            if marker.entity ~= nil then
                host:setActionbar("Entity disguise cannot be dyed!")
                lm_chatConsumer = nil
                return
            end
            lm_chatConsumer = function(x)
                -- TODO: figure out and handwrite a better blending algorithm so we can move 100% to pure setcolor
                if not vectors.hexToRGB(x) then
                    host:setActionbar("Invalid color!")
                    return
                end
                if marker.model == nil then
                    if x == "marker_blue" then
                        pings.lm_setSpecialColor(x, marker.id)
                    elseif x == "marker_teal" then
                        pings.lm_setSpecialColor(x, marker.id)
                    elseif x == "marker_red" then
                        pings.lm_setSpecialColor(x, marker.id)
                    elseif x == "marker_green" then
                        pings.lm_setSpecialColor(x, marker.id)
                    elseif x == "marker_white" then
                        pings.lm_setSpecialColor(x, marker.id)
                    else
                        pings.lm_setColor(x, marker.id)
                    end
                else
                    pings.lm_setModelColor(x, marker.id)
                end
                host:setActionbar("Set marker color to " .. x)
            end
            host:setActionbar("Type the hex code of the color in chat, or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Move to cursor")
        :item("ender_pearl")
        :onLeftClick(function()
            local pos = marker.positionFromRaycast()
            if marker.positionIsFree(pos) then
                pings.lm_move(pos, marker.id)
            end
        end)
    marker.page:newAction()
        :title("Move to player")
        :item("lead")
        :onLeftClick(function()
            if player:isLoaded() then
                local pos = marker.alignedPosition(player:getPos()) * 16
                if marker.positionIsFree(pos) then
                    pings.lm_move(pos, marker.id)
                end
            end
        end)
    marker.page:newAction()
        :title("Set scale")
        :item("wheat")
        :onLeftClick(function()
            if sneak_key:isPressed() then
                lm_chatConsumer = function(x)
                    local nx = tonumber(x)
                    if not nx then
                        host:setActionbar("Not a number!")
                        lm_preserve_consumer = false
                        return
                    end
                    lm_preserve_consumer = true
                    lm_chatConsumer = function(y)
                        local ny = tonumber(y)
                        if not ny then
                            host:setActionbar("Not a number!")
                            lm_preserve_consumer = false
                            return
                        end
                        lm_preserve_consumer = true
                        lm_chatConsumer = function(z)
                            local nz = tonumber(z)
                            if not nz then
                                host:setActionbar("Not a number!")
                                lm_preserve_consumer = false
                                return
                            end
                            pings.lm_setScale(vec(nx, ny, nz), marker.id)
                            host:setActionbar("Set scale to "..nx..", "..ny..", "..nz)
                        end
                        host:setActionbar("Type the new scale Z or 'stop' to cancel:")
                    end
                    host:setActionbar("Type the new scale Y or 'stop' to cancel:")
                end
                host:setActionbar("Type the new scale X or 'stop' to cancel:")
            else
                lm_chatConsumer = function(x)
                    local new_scale = tonumber(x)
                    if not new_scale then
                        host:setActionbar("Not a number!")
                        return
                    end
                    pings.lm_setScale(vec(new_scale, new_scale, new_scale), marker.id)
                    host:setActionbar("Set scale to "..x.."°")
                end
                host:setActionbar("Type the new scale (1 is default), or 'stop' to cancel:")
            end
        end)
    marker.page:newAction()
        :title("Delete")
        :item("iron_pickaxe")
        :onLeftClick(function() pings.lm_delete(marker.id) end)
    marker.page:newAction()
        :title("Disguise as mob")
        :item("ghast_spawn_egg")
        :onLeftClick(function()
            if sneak_key:isPressed() then
                -- NBT mode
                lm_chatConsumer = function(x)
                    pings.lm_disguise(x, marker.id, 0)
                end
                host:setActionbar("Type the new mob NBT in chat, 'disable' to disable disguise or 'stop' to cancel:")
            else
                -- Mob ID mode
                lm_chatConsumer = function(x)
                    pings.lm_disguise(x, marker.id, 1)
                end
                host:setActionbar("Type the new mob ID in chat, 'disable' to disable disguise or 'stop' to cancel:")
            end
        end)
    marker.page:newAction()
        :title("Disguise as model")
        :item("blaze_spawn_egg")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                pings.lm_disguise(x, marker.id, 2)
            end
            host:setActionbar("Type the model name in chat, 'disable' to disable disguise or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Set text height")
        :item("wheat")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                local new_height = tonumber(x)
                if not new_height then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setTextHeight(new_height, marker.id)
                host:setActionbar("Set text height to " .. x)
            end
            host:setActionbar("Type the new text height (34 is default, 16 is one block), or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Rotate")
        :item("compass")
        :onLeftClick(function()
            if sneak_key:isPressed() then
                lm_chatConsumer = function(x)
                    local nx = tonumber(x)%360
                    if not nx then
                        host:setActionbar("Not a number!")
                        lm_preserve_consumer = false
                        return
                    end
                    lm_preserve_consumer = true
                    lm_chatConsumer = function(y)
                        local ny = tonumber(y)%360
                        if not ny then
                            host:setActionbar("Not a number!")
                            lm_preserve_consumer = false
                            return
                        end
                        lm_preserve_consumer = true
                        lm_chatConsumer = function(z)
                            local nz = tonumber(z)%360
                            if not nz then
                                host:setActionbar("Not a number!")
                                lm_preserve_consumer = false
                                return
                            end
                            pings.lm_setRot(vec(nx, ny, nz), marker.id)
                            host:setActionbar("Set rotation to "..nx.."°X, "..ny.."°Y, "..nz.."°Z")
                        end
                        host:setActionbar("Type the new rotation Z or 'stop' to cancel:")
                    end
                    host:setActionbar("Type the new rotation Y or 'stop' to cancel:")
                end
                host:setActionbar("Type the new rotation X or 'stop' to cancel:")
            else
                lm_chatConsumer = function(x)
                    local new_rot = tonumber(x)%360
                    if not new_rot then
                        host:setActionbar("Not a number!")
                        return
                    end
                    pings.lm_setRot(vec(0, new_rot, 0), marker.id)
                    host:setActionbar("Set rotation to "..new_rot.."°")
                end
                host:setActionbar("Type the new rotation or 'stop' to cancel:")
            end
        end)
    marker.page:newAction()
        :title("Set light level")
        :item("daylight_detector")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                if x == "disable" then
                    pings.lm_setLight(nil, marker.id)
                    host:setActionbar("Light override disabled!")
                    return
                end
                local new_light = tonumber(x)
                if not new_light or new_light ~= math.floor(new_light) then
                    host:setActionbar("Not an integer!")
                    return
                end
                if new_light > 15 or new_light < 0 then
                    host:setActionbar("Out of range! Valid values are 0-15.")
                    return
                end
                pings.lm_setLight(new_light, marker.id)
                host:setActionbar("Set light level to " .. x)
            end
            host:setActionbar("Type the new light level (fullbright is 15), 'disable' to disable or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Save preset")
        :item("campfire")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                marker:saveToLMP(x)
                host:setActionbar("Saved preset as " .. x .. ".lmp (in figura/data/lumimarkers)")
            end
            host:setActionbar("Type a filename or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Load preset")
        :item("soul_campfire")
        :onLeftClick(function()
            lm_chatConsumer = function(x)
                local result = marker:loadFromLMP(x, sneak_key:isPressed())
                if result then
                    host:setActionbar(result)
                else
                    host:setActionbar("Loaded!")
                end
            end
            host:setActionbar("Type a filename or 'stop' to cancel:")
        end)
end

---Adds the given marker to the PageHolder.
---@param marker Marker
function PageHolder:insertMarker(marker)
    PageHolder.markerNext = PageHolder.markerNext + 1
    marker.id = PageHolder.markerNext
    PageHolder.genMarkerPage(marker)
    marker.action = ph.markerPage:newAction()
        :title("Marker")
        :item("snowball")
        :onLeftClick(function() action_wheel:setPage(marker.page) end)
    PageHolder.markers[PageHolder.markerNext] = marker

end

---Adds the given marker to the PageHolder at the specified ID.
---@param marker Marker
---@param id number
function PageHolder.syncMarker(marker, id)
    marker.id = id
    PageHolder.markers[id] = marker
end

function PageHolder.genZonePage(zone)
    zone.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(ph.zonePage)
            if lm_chatConsumer then
                host:setActionbar("Cancelled")
                lm_chatConsumer = nil
            end
        end)
    zone.page:newAction()
        :title("Move")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(ph.zonePage)
            if lm_chatConsumer then
                host:setActionbar("Cancelled")
                lm_chatConsumer = nil
            end
        end)
end

function events.chat_send_message(msg)
    if lm_chatConsumer then
        if msg ~= "stop" then
            lm_chatConsumer(msg)
        else
            host:setActionbar("Cancelled")
        end
        if not lm_preserve_consumer then
            lm_chatConsumer = nil
        end
        lm_preserve_consumer = false
        return nil
    else
        return msg
    end
end

PageHolder:reset()
action_wheel:setPage(PageHolder.markerPage)
lm_addActionWheel(PageHolder.markerPage, "lumiMarkers")

return PageHolder
