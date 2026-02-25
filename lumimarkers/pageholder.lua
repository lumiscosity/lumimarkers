---A class describing the UI and marker/zone storage.
---When implementing a new UI framework, the abstract calls have to be implemented.
---Only one instance of a PageHolder exists; get it by requiring this file.
---@class PageHolder
local PageHolder = {
    markerPage = action_wheel:newPage(),
    markers = {},
    markerNext = 0
}

---Regenerates the PageHolder.
function PageHolder:reset()
    PageHolder.markerPage = action_wheel:newPage()
    PageHolder.markerPage:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(pings.lm_spawnMarkerAtRaycast)

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
end

---Removes all markers/zones queued for deletion.
function PageHolder:gc()
    PageHolder:reset()
    action_wheel:setPage(PageHolder.markerPage)
end

function getMarker(id)
    return PageHolder.markers[id]
end

function PageHolder.genMarkerPage(marker)
    marker.page:newAction()
        :title("Back")
        :item("amethyst_cluster")
        :onLeftClick(function()
            action_wheel:setPage(ph.page)
            if chat_consumer then
                host:setActionbar("Cancelled")
                chat_consumer = nil
            end
        end)
    marker.page:newAction()
        :title("Rename")
        :item("name_tag")
        :onLeftClick(function()
            chat_consumer = function(x)
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
            chat_consumer = function(x)
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
                chat_consumer = nil
                return
            end
            chat_consumer = function(x)
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
            local pos = Marker.positionFromRaycast()
            if Marker.positionIsFree(pos) then
                pings.lm_move(pos, marker.id)
            end
        end)
    marker.page:newAction()
        :title("Move to player")
        :item("lead")
        :onLeftClick(function()
            if player:isLoaded() then
                local pos = Marker.alignedPosition(player:getPos()) * 16
                if Marker.positionIsFree(pos) then
                    pings.lm_move(pos, marker.id)
                end
            end
        end)
    marker.page:newAction()
        :title("Set scale")
        :item("wheat")
        :onLeftClick(function()
            chat_consumer = function(x)
                local new_scale = tonumber(x)
                if not new_scale then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setScale(new_scale, marker.id)
                host:setActionbar("Set scale to " .. x)
            end
            host:setActionbar("Type the new scale (1 is default), or 'stop' to cancel:")
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
                chat_consumer = function(x)
                    pings.lm_disguise(x, marker.id, 0)
                end
                host:setActionbar("Type the new mob NBT in chat, 'disable' to disable disguise or 'stop' to cancel:")
            else
                -- Mob ID mode
                chat_consumer = function(x)
                    pings.lm_disguise(x, marker.id, 1)
                end
                host:setActionbar("Type the new mob ID in chat, 'disable' to disable disguise or 'stop' to cancel:")
            end
        end)
    marker.page:newAction()
        :title("Disguise as model")
        :item("blaze_spawn_egg")
        :onLeftClick(function()
            chat_consumer = function(x)
                pings.lm_disguise(x, marker.id, 2)
            end
            host:setActionbar("Type the model name in chat, 'disable' to disable disguise or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Set text height")
        :item("wheat")
        :onLeftClick(function()
            chat_consumer = function(x)
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
            chat_consumer = function(x)
                local new_rot = tonumber(x)
                if not new_rot then
                    host:setActionbar("Not a number!")
                    return
                end
                pings.lm_setRot(new_rot, marker.id)
                host:setActionbar("Set rotation to "..x.."°")
            end
            host:setActionbar("Type the new rotation or 'stop' to cancel:")
        end)
    marker.page:newAction()
        :title("Set light level")
        :item("daylight_detector")
        :onLeftClick(function()
            chat_consumer = function(x)
                if x == "disable" then
                    pings.lm_setLight(nil, marker.id)
                    host:setActionbar("Light override disabled!")
                    return
                end
                local new_light = tonumber(x)
                if not new_light then
                    host:setActionbar("Not a number!")
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
end

---Adds the given marker to the PageHolder.
---@param marker Marker
function PageHolder:insertMarker(marker)
    PageHolder.markerNext = PageHolder.markerNext + 1
    marker.id = PageHolder.markerNext
    PageHolder.genMarkerPage(marker)
    marker.action = ph.page:newAction()
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

return PageHolder
