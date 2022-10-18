-- local dir = fs.getDir(shell.getRunningProgram())
local dir = "/stockpile"

libs = {
    graph = "fXPbzFLp",
    json = "4nRg9CHU"
}

function getFile(path)
    return dir .. path
end

function writeJsonFile(path, object)
    local str = json.encodePretty(object)
    local file = fs.open(path, "w")
    file.write(str)
    file.close()
end

-- import libraries
print("import libraries")
for lib, pastebin in pairs(libs) do
    local libPath = getFile("/lib/" .. lib)
    if fs.exists(libPath) == false then
        shell.run("pastebin get " .. pastebin .. " " .. libPath)
    end

    local success = os.loadAPI(libPath)
    print("loaded " .. lib .. ": " .. tostring(success))
end

-- load config
print("load config")
local cfgPath = getFile("/config.json")
local config = {}
if fs.exists(cfgPath) == false then
    config.crafting = {}
    config.crafting.max_request = 1024
    config.peripherals = {}
    config.peripherals.monitor = {}
    config.peripherals.monitor.name = "monitor_0"
    config.peripherals.me = "appliedenergistics2:controller_1"
    config.peripherals.monitor.scale = 0.5
    config.stock = {}
    config.stock[1] = {
        item = {
            name = "thermalfoundation:material",
            damage = 128
        },
        amount = 1024
    }
    writeJsonFile(cfgPath, config)
else
    config = json.decodeFromFile(cfgPath)
end

-- setup me
print("locate me")
local me = peripheral.wrap(config.peripherals.me)
print("found me: " .. peripheral.getName(me))

-- setup windows
print("locate monitor")
local monitor = peripheral.wrap(config.peripherals.monitor.name)
monitor.setTextScale(config.peripherals.monitor.scale);
local graphics = graph.Graphics:new(monitor);
print("found monitor: " .. peripheral.getName(monitor) .. " with size " .. graphics:getWidth() .. "x" .. graphics:getHeight())
local mainWidth = math.ceil(graphics:getWidth() / 3 * 2);
graphics:fillBox(1, 1, graphics:getWidth(), 1, "0");
graphics:write(1, 1, "Item Name", "f", "0");
graphics:write(mainWidth - 12, 1, "Total", "f", "0")
graphics:write(mainWidth - 6, 1, "Stock", "f", "0")
graphics:write(mainWidth + 2, 1, "Progress", "f", "0")
graphics:write(1, 2, string.rep("-", graphics:getWidth()), "0", "f")

local mainWindow = window.create(monitor, 1, 3, mainWidth, graphics:getHeight(), true)
local chartWindow = window.create(monitor, mainWidth + 2, 3, math.floor(graphics:getWidth() / 3) - 1, graphics:getHeight(), true)
local gMain = graph.Graphics:new(mainWindow)
print("main window: " .. gMain:getWidth() .. "x" .. gMain:getHeight())
local gChart = graph.Graphics:new(chartWindow)
print("chart window: " .. gChart:getWidth() .. "x" .. gChart:getHeight())
print("initialized graphics")

-- start render loop
-- coroutine.create(renderLoop)

function formatNumber(value)

    if math.floor(value / 1000000) > 0 then
        return string.format("%3.1fM", value / 1000000.0)
    end

    if math.floor(value / 10000) > 0 then
        return string.format("%.0fK", value / 1000.0)
    end

    return tostring(value)
end

function itemKey(item)
    return item.name .. "#" .. item.damage;
end

function getItems()
    local items = {}
    local contents = me.listAvailableItems();
    for k, v in pairs(contents) do
        items[itemKey(v)] = v
    end
    return items
end

local crafting = {};
function renderLoop()
    while true do
        -- mainWindow.clear()
        -- chartWindow.clear()
        local items = getItems()
        local y = 1

        for id, proc in pairs(crafting) do
            if proc.isFinished() or proc.isCanceled() then
                crafting[id] = nil
            end
        end

        for index, stockData in pairs(config.stock) do
            local item = me.findItem(stockData.item);
            local stock = stockData.amount

            if item ~= nil then
                local meta = item.getMetadata();
                local key = itemKey(meta);
                if (meta.count < stock and crafting[key] == nil and items[key].isCraftable) then
                    local toCraft = math.min(config.crafting.max_request, stock - meta.count);
                    crafting[key] = item.craft(toCraft)
                end

                -- print("render: " .. meta.displayName .. ", " .. meta.count .. ", " .. stock)
                renderItem(meta, stock, y);
                y = y + 1
            end
        end
    end
end

function renderItem(item, stock, y)
    if gMain:getHeight() < y then
        return
    end

    local width = gMain:getWidth()
    local color = "0"
    if (crafting[itemKey(item)] ~= nil) then
        color = "1"
    end

    mainWindow.setCursorPos(1, y)
    mainWindow.clearLine()
    gMain:write(1, y, item.displayName, color, "f")
    gMain:write(width - 12, y, formatNumber(item.count))
    gMain:write(width - 6, y, formatNumber(stock))
    local color = (math.fmod(y, 2) == 0 and "1" or "2")
    gChart:drawBarHorizontal(1, y, gChart:getWidth(), 1, math.min(stock, item.count), stock, color, "8", false, "8", false);
end

print("entering main loop...")
renderLoop()

