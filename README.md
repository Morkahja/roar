# ROAR Addon — Readme

ROAR is a lightweight Turtle WoW addon that plays a random battle-themed emote whenever you press a specific action-bar button. It is fully configurable: slot, chance, cooldown, and enable/disable state.

## Features

* Random emotes when pressing a chosen action slot
* Adjustable cooldown (no upper limit)
* Adjustable proc chance (0–100%)
* Watch mode to detect action slot numbers
* On/Off toggle without losing configuration
* Small tutorial built into the slash command

## Installation

Place the folder **roar** inside:

```
Interface/AddOns/
```

Make sure the folder contains:

* `roar.lua`
* `roar.toc`

Restart your game.

## Commands

Use `/roar` followed by a command:

* **slot <n>** — sets which action slot triggers the emote
* **watch** — prints slot numbers when pressing buttons
* **chance <0-100>** — probability that an emote fires
* **cd <seconds>** — cooldown between emotes
* **on / off** — enable or disable the emote firing
* **info** — show current settings
* **reset** — clears the stored slot
* **save** — saves current settings to SavedVariables
* **tutorial** — short guide on how to set up the addon

Example setup:

```
/roar watch
# press your ability until you see its slot number
/roar slot 3
/roar chance 40
/roar cd 12
/roar on
```

## How It Works

ROAR hooks into the `UseAction` function. Each time you press your chosen action slot, the addon checks:

* Is ROAR enabled?
* Does the slot match your configured slot?
* Is the cooldown ready?
* Does the random chance succeed?

If all conditions pass, a random emote from the pool fires.

## Notes

* All emotes use WoW’s built-in `DoEmote()` tokens.
* Works on Vanilla/Turtle WoW’s Lua 5.0 environment.
* Does *not* alter gameplay or combat decisions—pure flavour.

## License

Free to modify, copy, or shout into the void. Enjoy your glorious battle-cries.

## Author

ROAR is created and maintained by **Babunigaming (Morkahja / Buxbrew)**.

## Emotes Used

The ROAR addon draws from the following built‑in emotes when a trigger fires:

* **/roar** – Fierce shout.
* **/charge** – Dynamic charge‑up animation.
* **/cheer** – Celebration moment.
* **/bored** – Idle impatience.
* **/flex** – Show of strength.

These are selected at random whenever your configured action slot activates and passes the chance + cooldown rules.
