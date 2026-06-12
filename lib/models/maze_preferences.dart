/// Global preferences for the Maze game.
/// These can be toggled by the user in the settings menu.
class MazePreferences {
  /// If true, any location that leads to a bridge is considered a decision point,
  /// causing the auto-move to stop, even if the player cannot afford the bridge.
  static bool alwaysStopAtBridges = false;
}
