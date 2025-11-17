# Hot-Swap Networking Guide

## Quick Start

The qantumgoose project now supports **hot-swapping** between two networking systems with just a single script change!

## How to Switch Modes

### Option 1: In the Godot Editor (Easiest)
1. Open `ui/multiplayer_ui.tscn` in the editor
2. Select the `MultiplayerUI` node
3. In the Inspector, find the **"Networking Mode"** property
4. Change it from:
   - `LOBBY_BASED` (qantumgoose style - default)
   - `SOCKET_BASED` (bomber demo style)

### Option 2: In Code
Open `ui/multiplayer_ui.gd` and change line 6:

```gdscript
# For lobby-based (qantumgoose style):
@export var networking_mode: SteamNetworkAdapter.ConnectionMode = SteamNetworkAdapter.ConnectionMode.LOBBY_BASED

# For socket-based (bomber demo style):
@export var networking_mode: SteamNetworkAdapter.ConnectionMode = SteamNetworkAdapter.ConnectionMode.SOCKET_BASED
```

## What's the Difference?

### LOBBY_BASED (Default - qantumgoose style)
- Uses `host_with_lobby()` and `connect_to_lobby()`
- Simpler API, more integrated with Steam lobbies
- Automatically handles lobby connections

### SOCKET_BASED (bomber demo style)
- Uses `create_host()` and `create_client()`
- Lower-level, more control
- Requires getting Steam ID from lobby owner manually

## Technical Details

The `SteamNetworkAdapter` class (in `other/steam_network_adapter.gd`) handles all the differences automatically. The `multiplayer_ui.gd` script uses the adapter based on the selected mode.

Both modes use the same underlying `SteamMultiplayerPeer` addon, so they're functionally equivalent - just different APIs!

## Joining by Lobby ID Code

Both modes now support joining by lobby ID code (like the bomber demo):

1. **In the Steam area**, you'll see a "Join by Lobby ID Code" button
2. Enter the lobby ID code in the text field
3. Click the button to join

**How it works:**
- **Lobby-based mode**: Directly connects via the lobby
- **Socket-based mode**: Joins the Steam lobby first to get the host's Steam ID, then connects via socket (bomber demo style)

This matches the bomber demo's behavior where you could enter a lobby ID to join!

## Testing

1. Set the mode you want to test
2. Run the game
3. Try hosting and joining games
4. Try joining by lobby ID code
5. Switch modes and test again - no other changes needed!

