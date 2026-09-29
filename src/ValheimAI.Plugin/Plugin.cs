// Milestone-1 plugin skeleton.
// Concrete BepInEx/Valheim API references will be wired after validating the
// current Valheim 1.0 assemblies on the target Windows machine.

namespace ValheimAI.Plugin;

public static class PluginMetadata
{
    public const string Guid = "com.valheimai.agent";
    public const string Name = "ValheimAI Agent";
    public const string Version = "0.1.0";
}

public sealed class AgentState
{
    public string PlayerName { get; set; } = string.Empty;
    public float Health { get; set; }
    public float MaxHealth { get; set; }
    public float Stamina { get; set; }
    public Vec3 Position { get; set; } = new();
}

public sealed class Vec3
{
    public float X { get; set; }
    public float Y { get; set; }
    public float Z { get; set; }
}
