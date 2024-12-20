--- A class describing the main page.
---@class PageHolder
local PageHolder = {
    page = 0,
    markers = {}
}

---@param m markers
---@return PageHolder
function PageHolder:new(m)
    local newObject = setmetatable({}, self)
    self.__index = self
    self.page = action_wheel:newPage()
    self.markers = {}
    return newObject
end

function PageHolder:insert(marker)
    table.insert(self.markers, marker)
end

function PageHolder:remove(marker)
    self.page = action_wheel:newPage()
    self.page:newAction()
    :title("Spawn marker")
    :item("amethyst_shard")
    :onLeftClick(spawnMarkerAtRaycast)

    local newMarkers = {}

    for _, v in pairs(self.markers) do
        if v.marker:getVisible() == true then
            table.insert(newMarkers, v)
        end
    end

    self.markers = newMarkers

    for _, v in pairs(self.markers) do
            self.page:newAction()
            :title("Marker")
            :item("snowball")
            :onLeftClick(function() action_wheel:setPage(v.page) end)
    end

    action_wheel:setPage(self.page)
end

return PageHolder
