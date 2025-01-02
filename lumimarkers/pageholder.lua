---A class describing the main page. Only one instance of a PageHolder exists.
---@class PageHolder
local PageHolder = {
    page = action_wheel:newPage(),
    markers = {},
    next_id = 0
}

---Regenerates the PageHolder.
function PageHolder:reset()
    PageHolder.page = action_wheel:newPage()
    PageHolder.page:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(pings.lm_spawnMarkerAtRaycast)

    next_id = 0
    local newMarkers = {}

    for _, v in pairs(PageHolder.markers) do
        if not v.removed then
            next_id = next_id + 1
            v.id = next_id
            newMarkers[next_id] = v
        end
    end

    PageHolder.markers = newMarkers

    for _, v in pairs(PageHolder.markers) do
        PageHolder.page:setAction(-1, v.action)
    end
end

---Adds the given marker to the PageHolder.
---@param marker Marker
function PageHolder:insert(marker)
    next_id = next_id + 1
    marker.id = next_id
    PageHolder.markers[next_id] = marker
end

function PageHolder.sync(marker, id)
    marker.id = id
    PageHolder.markers[id] = marker
end

---Removes markers queued for deletion.
function PageHolder:remove()
    PageHolder:reset()
    action_wheel:setPage(PageHolder.page)
end

function getMarker(id)
    return PageHolder.markers[id]
end

return PageHolder
