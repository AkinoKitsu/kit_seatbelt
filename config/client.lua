return {
    keybind = 'B',                             -- Keybind to toggle seatbelt (https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/)
    useMPH = true,                             -- Use MPH instead of KMH
    minSpeedUnbuckled = 20.0,                  -- Minimum speed to fly through windscreen when seatbelt is off
    minSpeedBuckled = 160.0,                   -- Minimum speed to fly through windscreen when seatbelt is on
    harness = {
        disableFlyingThroughWindscreen = true, -- Disable flying through windscreen when harness is on
        minSpeed = 200.0,                      -- If the above is set to false, minimum speed to fly through windscreen when harness is on
        buckleTime = 5000,                     -- Time to buckle/unbuckle the harness
        installTime = 5000,                    -- Time to install/remove the harness
        preventDriveWhileBuckling = true,      -- Prevent driving while buckling the harness
    }
}