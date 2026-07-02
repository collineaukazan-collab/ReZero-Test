# AI_CONTEXT — ReZero-Test

## Concept
Roblox loop game:
- The player climbs an infinite tower/staircase.
- If the player falls from the tower, they die.
- On death, they respawn at the bottom.
- The higher they climbed during the run, the more money they earn.
- Money gain is linear: reward = best run height in studs × money multiplier.
- Upgrades later increase the money multiplier and other abilities.

## Units
- Height is measured in Roblox studs.
- Floors are calculated from stair segments.
- One stair segment is approximately 180 studs high.

## Important rules
- Player data must be handled on the server.
- The server tracks current height, best height, money, and multipliers.
- The client can render nearby stairs to avoid lag.
- The player always starts at the bottom when joining.
- We do not save player position.
- Leaderboard shows current studs and best studs.

## Architecture
- server/Services: server authority, player data, rewards, height tracking.
- client/Controllers: UI, graphics options, stair rendering.
- shared/Config: shared balancing values.
- shared/Utils: reusable helpers.

## Performance goal
The world is infinite, but the client only renders nearby stair segments.
Graphics quality controls render distance:
- Low: short distance
- Medium: balanced
- High: longer distance
