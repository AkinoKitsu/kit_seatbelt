SetConvarReplicated('game_enableFlyThroughWindscreen', 'true')
local config = require 'config.server'

local function isVehicleOwned(plate)
    return exports.qbx_vehicles:DoesPlayerVehiclePlateExist(plate)
end

local function hasHarness(plate)
    return MySQL.scalar.await('SELECT plate FROM harness_vehicles WHERE plate = ?', { plate }) ~= nil
end

local function setHarnessState(vehicle, state)
    if vehicle then
        Entity(vehicle).state:set('harness', state, true)
    end
end

local function installHarness(plate, vehicle, action)
    if not plate or not vehicle or not action then return end

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

local function getPlateFromFakePlate(fakePlate)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE fakeplate = ?', { fakePlate })
    if result then
        return result
    end
end

local function handleVehicleSpawn(veh, isNetId)
    local vehicle = isNetId and NetworkGetEntityFromNetworkId(veh) or veh
    local plate = GetVehicleNumberPlateText(vehicle)
    local realPlate
    if not plate or not vehicle then return end

    if config.harness.useBrazzersFakeplates then
        realPlate = getPlateFromFakePlate(plate)
    end
    if realPlate then
        plate = realPlate
    end
    if not hasHarness(plate) then return end
    setHarnessState(vehicle, true)
end

lib.callback.register('kit_seatbelt:server:installHarness', function(source, plate, action)
    local src = source
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    if not plate or not action or not veh then return false end

    local hasHarnessState = Entity(veh).state.harness

    if action == 'install' then
        if hasHarnessState then return false end
        if not exports.ox_inventory:RemoveItem(src, 'harness', 1) then return false end
    end

    if action == 'remove' then
        if not hasHarnessState then return false end
        if not exports.ox_inventory:AddItem(src, 'harness', 1) then return false end
    end

    return installHarness(plate, veh, action)
end)

RegisterNetEvent('qbx_garages:server:vehicleSpawned', function(veh)
    handleVehicleSpawn(veh, false)
end)

RegisterNetEvent('kit_seatbelt:server:jgVehicleSpawned', function(netId)
    handleVehicleSpawn(netId, true)
end)