# Changelog

## v1.0.0

First public release, on CurseForge and Wago.

- Counts your Al'Aketh Cultist's Ears against Exalted with the Nightclaw Druids: standing, ears in bags and bank,
  rep and turn-ins left, and ears still to collect.
- Opens on Zephras Isle, hands the ears in at Vayn Moongaze (Shift skips), and puts a line on the ear's tooltip.

## v0.4.1

- A logo, in the AddOns list and the addon compartment.
- The quest giver is Vayn Moongaze, not Moonclaw: the Target button now finds him. It also learns his name from
  the turn-in window, so it works in any client language (skipped safely if the game hides the name).

## v0.4.0

- Auto turn-in: talk to Vayn Moongaze with enough ears and they go in by themselves. Hold Shift to skip,
  `/ears turnin` to switch it off. Only the ear quest, and never when the reward is a choice.
- A Target Vayn Moongaze button on the panel. Pair it with your Interact with Target key.
- The panel waits for the end of combat to open or close (the button is a secure one).

## v0.3.1

- The standing bar is easier to see: a faint gold track, a little taller, and always a sliver of gold at the start.
- Turn-ins shows just the count; the ears are under Still to collect.

## v0.3.0

- New look, after wowdb.dev: a dark navy panel with hairline borders and a gold accent, Oswald for labels
  and JetBrains Mono for numbers, a gold progress bar for your standing, and the numbers as a list of facts.

## v0.2.0

- The panel opens by itself when you arrive on Zephras Isle (Shadowgale Forest, the Shrine of Akir, Gustberry
  Lowlands) and closes when you leave. Close it there and it stays closed until your next visit; open it
  yourself and it stays open everywhere. Not once you're Exalted. `/ears auto` turns this off.

## v0.1.0

- First version: panel and ear tooltip with ears carried, rep to Exalted with the Nightclaw Druids, and
  ears still to collect. Learns ears and rep per turn-in from the game, and notices if turn-ins stop giving rep.
