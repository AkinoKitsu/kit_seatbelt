local config = require 'config.client'
local playerState = LocalPlayer.state
local speedMultiplier = config.useMPH and 2.237 or 3.6
local minSpeeds = {
    unbuckled = config.minSpeedUnbuckled / speedMultiplier,
    buckled = config.minSpeedBuckled / speedMultiplier,
    harness = config.harness.minSpeed / speedMultiplier
}

-- Functions
local function playBuckleSound(seatbelt)
    qbx.loadAudioBank('audiodirectory/seatbelt_sounds')
    qbx.playAudio({
        audioName = seatbelt and 'carbuckle' or 'carunbuckle',
        audioRef = 'seatbelt_soundset',
        source = cache.ped
    })
    ReleaseNamedScriptAudioBank('audiodirectory/seatbelt_sounds')
end

local function progressBar(label, duration, disable)
    if lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = false,
            disable = disable or {
                car = true,
                combat = true,
            }
        }) then
        return true
    end
    return false
end

local buckling = false
local function toggleSeatbelt()
    if not cache.vehicle then return end
    if buckling then return end

    local seatbeltOn = not playerState.seatbelt
    playerState.seatbelt = seatbeltOn

    buckling = true
    if Entity(cache.vehicle).state.harness then
        local canFlyThroughWindscreen = not seatbeltOn
        if config.harness.disableFlyingThroughWindscreen then
            SetPedConfigFlag(cache.ped, 32, canFlyThroughWindscreen) -- PED_FLAG_CAN_FLY_THRU_WINDSCREEN
        else
            local minSpeed = seatbeltOn and minSpeeds.harness or
                (playerState.seatbelt and minSpeeds.buckled or minSpeeds.unbuckled)
            SetFlyThroughWindscreenParams(minSpeed, 1.0, 17.0, 10.0)
        end
        if seatbeltOn then
            if not progressBar(locale('progress.buckleHarness'), config.harness.buckleTime, { car = config.harness.preventDriveWhileBuckling, combat = true, }) then
                return
            end
        end
    else
        SetFlyThroughWindscreenParams(seatbeltOn and minSpeeds.buckled or minSpeeds.unbuckled, 1.0, 17.0, 10.0)
    end
    TriggerEvent('seatbelt:client:ToggleSeatbelt')
    playBuckleSound(seatbeltOn)
    buckling = false
end

local function installHarness(action)
    if not action then return end
    if not cache.vehicle then
        lib.notify({
            title = 'Harness',
            description = locale('notify.notInCar'),
            type = 'error'
        })
        return
    end

    local harnessState = Entity(cache.vehicle).state.harness
    local label

    if action == 'remove' then
        label = locale('progress.removeHarness')
        if not harnessState then
            lib.notify({
                title = 'Harness',
                description = locale('notify.noHarnessInstalled'),
                type = 'error'
            })
            return
        end
    elseif action == 'install' then
        label = locale('progress.attachHarness')
        if harnessState then
            lib.notify({
                title = 'Harness',
                description = locale('notify.harnessAlreadyInstalled'),
                type = 'error'
            })
            return
        end

        local count = exports.ox_inventory:Search('count', 'harness')
        if not count or count == 0 then
            lib.notify({
                title = 'Harness',
                description = locale('notify.noHarnessItem'),
                type = 'error'
            })
            return
        end
    end
    if not progressBar(label, config.harness.installTime, { car = true, combat = true, move = true }) then return end

    local plate = qbx.getVehiclePlate(cache.vehicle)
    local res = lib.callback.await('qbx_seatbelt:server:installHarness', 1000, plate, action)
    if not res then
        lib.notify({
            title = 'Harness',
            description = locale('notify.harnessFailed'),
            type = 'error'
        })
        return
    end
    local notifyText = action == 'install' and 'notify.harnessInstalled' or 'notify.harnessRemoved'
    lib.notify({
        title = 'Harness',
        description = locale(notifyText),
        type = 'success'
    })
end

exports('installHarness', installHarness)

local function seatbelt()
    while cache.vehicle do
        local sleep = 1000
        if playerState.seatbelt then
            sleep = 0
            DisableControlAction(0, 75, true)
            DisableControlAction(27, 75, true)
        end
        Wait(sleep)
    end
    playerState.seatbelt = false
end

-- Export
function HasHarness()
    return Entity(cache.vehicle).state.harness or false
end

--- @deprecated Use `state.seatbelt` instead
exports('HasHarness', HasHarness)

-- Main Thread
CreateThread(function()
    SetFlyThroughWindscreenParams(minSpeeds.unbuckled, 1.0, 17.0, 10.0)
end)

lib.onCache('vehicle', function()
    Wait(500)
    seatbelt()
end)

-- Register Key
lib.addKeybind({
    name = 'toggleseatbelt',
    description = locale('toggleCommand'),
    defaultKey = config.keybind,
    onPressed = function()
        if not cache.vehicle or IsPauseMenuActive() then return end
        local class = GetVehicleClass(cache.vehicle)
        if class == 8 or class == 13 or class == 14 then return end
        toggleSeatbelt()
    end
})