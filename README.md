# kit_seatbelt

---

Persistent harnesses for player owned vehicles!
Harnesses may still be installed on non owned or "local" vehicles, but will not persist if the vehicle is deleted.

Some original code from [qbx_seatbelt](https://github.com/Qbox-project/qbx_seatbelt). Harness functionality has been completely rewritten.

---

### Use

- Get Harness Kit
- Get Harness
- Sit in vehicle
- Right click Harness Kit
- Click install or remove Harness

### Install

-   Replace qbx_seatbelt with kit_seatbelt.
-   Run the included sql file.
-   Add item(s) to inventory.
## Item

-# ox_inventory:
```lua
['harness_kit'] = {
    label = 'Harness Kit',
    weight = 220,
    stack = true,
    close = true,
    buttons = {
        {
            label = 'Install Harness',
            action = function()
                exports.kit_seatbelt:installHarness('install')
            end
		},
        {
            label = 'Remove Harness',
            action = function()
                exports.kit_seatbelt:installHarness('remove')
            end
		},
    }
},
```
