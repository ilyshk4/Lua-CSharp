using Lua.IO;

namespace Lua.Platforms;

public record LuaPlatform(
    ILuaFileSystem FileSystem,
    ILuaOsEnvironment OsEnvironment,
    ILuaStandardIO StandardIO,
    TimeProvider TimeProvider
);
