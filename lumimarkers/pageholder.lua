---A class describing the main page. Only one instance of a PageHolder exists.
---@class PageHolder
local PageHolder = {
    page = action_wheel:newPage(),
    markers = {}
}

---Regenerates the PageHolder.
function PageHolder:reset()
    PageHolder.page = action_wheel:newPage()
    PageHolder.page:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(spawnMarkerAtRaycast)

    for _, v in pairs(PageHolder.markers) do
        PageHolder.page:setAction(-1, v.action)
    end
end

function PageHolder:insert(marker)
    table.insert(PageHolder.markers, marker)
end

---Removes the given marker from the PageHolder.
---@param marker Marker
function PageHolder:remove(marker)
    local newMarkers = {}

    for _, v in pairs(PageHolder.markers) do
        if not v.removed then
            table.insert(newMarkers, v)
        end
    end

    PageHolder.markers = newMarkers

    PageHolder:reset()

    action_wheel:setPage(PageHolder.page)
end

return PageHolder
