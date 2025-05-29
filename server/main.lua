SetConvarReplicated('game_enableFlyThroughWindscreen', 'true')

local function isVehicleOwned(plate)
    return exports.qbx_vehicles:DoesPlayerVehiclePlateExist(plate)
end

local function hasHarness(plate)
    return MySQL.scalar.await('SELECT plate FROM harness_vehicles WHERE plate = ?', { plate }) ~= nil
end

function GetVehicleByPlate(plate)
    if not plate then return nil end

    for _, vehicle in ipairs(GetAllVehicles() or {}) do
        if GetVehicleNumberPlateText(vehicle) == plate then
            return vehicle
        end
    end

    return nil
end

local function setHarnessState(vehicle, state)
    if vehicle then
        Entity(vehicle).state:set('harness', state, true)
    end
end

local function installHarness(plate, action)
    if not plate or not action then return end

    local vehicle = GetVehicleByPlate(plate)
    if not vehicle then return end

    if action == 'install' then
        if isVehicleOwned(plate) then
            MySQL.insert.await('INSERT INTO harness_vehicles (plate) VALUES (?)', { plate })
        end
        setHarnessState(vehicle, true)
        return true
    elseif action == 'remove' then
        if isVehicleOwned(plate) then
            MySQL.update.await('DELETE FROM harness_vehicles WHERE plate = ?', { plate })
        end
        setHarnessState(vehicle, false)
        return true
    end
    return false
end

lib.callback.register('qbx_seatbelt:server:installHarness', function(source, plate, action)
    local src = source
    if not plate or not action then return false end
    local hasHarness = hasHarness(plate)
    local veh = GetVehicleByPlate(plate)
    if not veh then return false end

    if action == 'install' then
        if hasHarness then return false end
        if not exports.ox_inventory:RemoveItem(src, 'harness', 1) then return false end
    end

    if action == 'remove' then
        if not hasHarness then return false end
        if not exports.ox_inventory:AddItem(src, 'harness', 1) then return false end
    end

    return installHarness(plate, action)
end)

RegisterNetEvent('qbx_garages:server:vehicleSpawned', function(veh)
    local vehicle = veh
    local plate = GetVehicleNumberPlateText(veh)
    if not plate then return end
    if not vehicle then return end

    if hasHarness(plate) then
        setHarnessState(vehicle, true)
    end
end)