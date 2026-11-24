# Nightclaw Ears

A small **WoW Forever** addon for the Nightclaw Druids of Shadowgale Forest. It counts your
**Al'Aketh Cultist's Ears** and works out how many more the druids want before you're **Exalted**.

## What it shows

A movable panel. It **opens by itself when you arrive on Zephras Isle**, where the ears drop and the druids
live, and closes when you leave. Close it there and it stays closed until your next visit; open it yourself
(`/ears`, or the addon compartment button) and it stays open everywhere. Once you're Exalted it no longer
pops up. It shows:

- your Nightclaw Druids standing and progress through it
- ears in your bags (and in your bank, once you've opened it this session)
- rep left to Exalted, how many turn-ins that is, and how many ears you still have to collect

The ear's tooltip gets a line too: *Nightclaw Druids: 971 more ears to Exalted*.

## How it counts

| | |
|---|---|
| Faction | Nightclaw Druids (2758). Exalted begins at 42,000 standing above Neutral |
| First quest | *Mercy Falls on Deaf Ears* (93165): 5 ears, 1,000 rep, once. Counted until you've done it |
| Repeatable | *More Al'Aketh Ears* (93459), Vayn Moonclaw: 200 rep per turn-in |

The quest text says the repeatable takes 10 ears, but its objective data and Wowhead say 5, so the addon
starts at **5 ears = 200 rep** and corrects itself:

- **ears per turn-in** are read from the turn-in window when you talk to Vayn Moonclaw
- **rep per turn-in** is read from the reputation you actually gain
- if a turn-in gives **no** reputation, the repeatable has a cap; the panel says at which standing

It prints a line when it learns either number, and after each turn-in.

## Commands

| | |
|---|---|
| `/ears` | show or hide the panel |
| `/ears auto` | turn opening on Zephras Isle on or off |
| `/ears lock` | lock or unlock the panel (drag to move) |
| `/ears reset` | move the panel back to the middle |

Saved variables: `NightclawEarsDB` (account-wide: panel position, learned ears and rep per turn-in, whether it opens on Zephras Isle).

## Look and fonts

The panel follows [wowdb.dev](https://wowdb.dev)'s design: its colours, a hairline border, and its two
typefaces, shipped in `media/fonts`:

- **Oswald** (labels, standing), Copyright 2016 The Oswald Project Authors
- **JetBrains Mono** (numbers), Copyright 2020 The JetBrains Mono Project Authors

Both are under the SIL Open Font License 1.1; the licence texts are next to the fonts.
