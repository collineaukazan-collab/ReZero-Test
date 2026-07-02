# Architecture

## Server
The server is responsible for:
- loading and saving player data;
- calculating current height;
- calculating best height;
- calculating money rewards;
- creating leaderstats;
- respawning the player at the bottom;
- preventing the client from directly modifying progression.

## Client
The client is responsible for:
- rendering nearby stair segments;
- destroying far stair segments;
- showing UI;
- handling graphics quality options.

## Shared
Shared files contain:
- game configuration;
- utility functions;
- constants used by both server and client.

## Stair rendering
The staircase is infinite in theory.
The client only keeps a limited number of stair segments around the player.

A segment is considered 180 studs high by default.

If a model named `StairSegment` exists in `ReplicatedStorage/Assets`, the client clones it.
If no model exists, the client creates a simple temporary spiral staircase for testing.
