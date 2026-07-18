# Lua-CSharp Public API Reference

Complete reference for all public types in the `Lua` namespace and its sub-namespaces.

---

## Namespace: `Lua`

### `LuaState` — Lua execution environment

`LuaState` is the primary entry point. Each instance represents one Lua thread (coroutine-aware). Implements `IDisposable`.

```csharp
public sealed class LuaState : IDisposable
```

#### Factory

| Method | Description |
|--------|-------------|
| `static LuaState Create(LuaPlatform? platform = null)` | Creates a new root Lua state. If no platform is provided, a default desktop platform is used. |

#### Thread & Coroutine Management

| Member | Description |
|--------|-------------|
| `LuaState CreateThread()` | Creates a new non-coroutine thread sharing the same global state. |
| `LuaState CreateCoroutine(LuaFunction function, bool isProtectedMode = false)` | Creates a coroutine thread from a function. |
| `LuaThreadStatus GetStatus()` | Returns the thread status. |
| `void UnsafeSetStatus(LuaThreadStatus status)` | Directly sets the thread status (use with caution). |
| `bool IsCoroutine` | Whether this state is a coroutine. |
| `bool CanResume` | Whether this coroutine can be resumed (status == `Suspended`). |
| `LuaFunction? CoroutineFunction` | The function associated with this coroutine, if any. |
| `LuaState MainThread` | The root/main thread of this Lua universe. |

#### Execution

| Method | Description |
|--------|-------------|
| `ValueTask<int> RunAsync(LuaFunction function, CancellationToken ct = default)` | Run a function with no arguments. Returns the number of return values on the stack. |
| `ValueTask<int> RunAsync(LuaFunction function, int argumentCount, CancellationToken ct = default)` | Run a function with arguments already pushed on the stack. |
| `ValueTask<int> RunAsync(LuaFunction function, int argumentCount, int returnBase, CancellationToken ct = default)` | Full-control execution with explicit return base. |

#### Coroutine Resume / Yield

| Method | Description |
|--------|-------------|
| `ValueTask<int> ResumeAsync(LuaFunctionExecutionContext context, CancellationToken ct = default)` | Resumes a coroutine with execution context. |
| `ValueTask<int> ResumeAsync(LuaStack stack, CancellationToken ct = default)` | Resumes a coroutine passing a pre-populated stack. |
| `ValueTask<int> YieldAsync(LuaFunctionExecutionContext context, CancellationToken ct = default)` | Yields from a coroutine. |
| `ValueTask<int> YieldAsync(LuaStack stack, CancellationToken ct = default)` | Yields with values on a pre-populated stack. |

#### Compilation (Loading)

| Method | Description |
|--------|-------------|
| `LuaClosure Load(ReadOnlySpan<char> chunk, string chunkName, LuaTable? environment = null)` | Compiles Lua source text into a `LuaClosure`. |
| `LuaClosure Load(ReadOnlySpan<byte> chunk, string? chunkName, string mode = "bt", LuaTable? environment = null)` | Loads from bytes — text (`"t"`), binary (`"b"`), or auto-detect (`"bt"`). |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `Stack` | `LuaStack` | The thread's evaluation stack. |
| `Environment` | `LuaTable` | Global environment table (`_G`). |
| `Registry` | `LuaTable` | Registry table (shared across all threads in the same universe). |
| `LoadedModules` | `LuaTable` | `package.loaded` table. |
| `PreloadModules` | `LuaTable` | `package.preload` table. |
| `ModuleLoader` | `ILuaModuleLoader?` | Custom module loader for `require()`. |
| `Platform` | `LuaPlatform` | Platform abstraction. |
| `IsRunning` | `bool` | Whether the thread has an active call stack. |
| `CallStackFrameCount` | `int` | Number of frames on the call stack. |

#### Diagnostics

| Method | Description |
|--------|-------------|
| `ref readonly CallStackFrame GetCurrentFrame()` | Gets the topmost stack frame. |
| `ReadOnlySpan<LuaValue> GetStackValues()` | Snapshot of the current stack values. |
| `ReadOnlySpan<CallStackFrame> GetCallStackFrames()` | Snapshot of the call stack. |
| `LuaTable GetCurrentEnvironment()` | Finds the current function's `_ENV` table. |
| `Traceback GetTraceback()` | Gets a traceback for the current call stack. |
| `void SetHook(LuaFunction? hook, string mask, int count = 0)` | Sets debug hooks (`'l'` = line, `'c'` = call, `'r'` = return). |

#### IDisposable

| Method | Description |
|--------|-------------|
| `void Dispose()` | Releases thread resources. Throws if still running. |

---

### `LuaValue` — Discriminated union value type

A `readonly struct` that represents any Lua value: nil, boolean, number, string, function, thread, table, light userdata, or userdata.

```csharp
public readonly struct LuaValue : IEquatable<LuaValue>
```

#### Static

| Member | Description |
|--------|-------------|
| `LuaValue Nil` | The nil value. |
| `static LuaValue FromObject(object obj)` | Converts a .NET object via pattern matching. |
| `static LuaValue FromUserData(ILuaUserData? userData)` | Wraps an `ILuaUserData`. |
| `static string ToString(LuaValueType type)` | Returns the Lua name for a type enum (e.g. `"table"`). |
| `static bool TryGetLuaValueType(Type type, out LuaValueType result)` | Maps a .NET `Type` to `LuaValueType`. |

#### Implicit Conversions (C# → LuaValue)

```
bool        → LuaValue
double      → LuaValue
string      → LuaValue
LuaTable    → LuaValue
LuaFunction → LuaValue
LuaState    → LuaValue
```

#### Properties

| Member | Description |
|--------|-------------|
| `LuaValueType Type` | The discriminated type tag. |

#### Methods

| Method | Description |
|--------|-------------|
| `T Read<T>()` | Reads as type `T`; throws `InvalidOperationException` on mismatch. |
| `bool TryRead<T>(out T result)` | Non-throwing typed read. |
| `bool ToBoolean()` | Lua truthiness test (only `nil` and `false` are falsy). |
| `bool Equals(LuaValue other)` | Value equality. |
| `bool EqualsForDict(LuaValue other)` | Dictionary-key equality (same as `Equals` but skips nil-nil check). |
| `string TypeToString()` | Returns Lua type name (`"nil"`, `"number"`, etc.). |
| `override string ToString()` | String representation. |

#### Operators

`==` and `!=` — delegates to `Equals`.

---

### `LuaValueType` — Value type enum

```csharp
public enum LuaValueType : byte
{
    Nil,
    Boolean,
    String,
    Number,
    Function,
    Thread,
    LightUserData,
    UserData,
    Table
}
```

---

### `LuaFunction` — Callable function (base class)

Base class for all callable Lua functions.

```csharp
public class LuaFunction
```

#### Constructors

| Constructor | Description |
|-------------|-------------|
| `LuaFunction(string name, Func<LuaFunctionExecutionContext, CancellationToken, ValueTask<int>> func)` | Named C# function. |
| `LuaFunction(Func<LuaFunctionExecutionContext, CancellationToken, ValueTask<int>> func)` | Anonymous (name defaults to `"anonymous"`). |

#### Properties

| Property | Description |
|----------|-------------|
| `string Name` | Function name. |

#### Known Subclasses

| Class | Description |
|-------|-------------|
| `LuaClosure` (in `Lua.Runtime`) | A compiled Lua function with upvalues. |
| `CSharpClosure` (in `Lua.Runtime`) | A C# function with upvalues. |

---

### `LuaFunctionExecutionContext` — Context for C# function calls

A `readonly record struct` passed to every C# function callable from Lua. This is the primary API for writing C# functions.

```csharp
public readonly record struct LuaFunctionExecutionContext
```

#### Properties

| Property | Description |
|----------|-------------|
| `LuaState State` | The executing Lua state. |
| `int ArgumentCount` | Number of arguments passed. |
| `int ReturnFrameBase` | Base position for return values on the stack. |
| `int FrameBase` | Base of the function's stack frame. |
| `ReadOnlySpan<LuaValue> Arguments` | The arguments as a span. |
| `ReadOnlyMemory<LuaValue> ArgumentsMemory` | The arguments as a memory. |

#### Argument Access

| Method | Description |
|--------|-------------|
| `bool HasArgument(int index)` | Checks if an argument exists and is not nil. |
| `LuaValue GetArgument(int index)` | Gets argument by index; throws if missing. |
| `T GetArgument<T>(int index)` | Gets argument with type checking; throws descriptive error on mismatch. |

#### Return Values

| Method | Description |
|--------|-------------|
| `int Return()` | Return 0 values. Returns `1` (for the return value count convention). |
| `int Return(LuaValue result)` | Return 1 value. |
| `int Return(LuaValue, LuaValue)` | Return 2 values. |
| `int Return(LuaValue, LuaValue, LuaValue)` | Return 3 values. |
| `int Return(ReadOnlySpan<LuaValue> results)` | Return multiple values. |
| `Span<LuaValue> GetReturnBuffer(int count)` | Pre-allocate a return buffer on the stack. |

#### Other

| Method | Description |
|--------|-------------|
| `CSharpClosure? GetCsClosure()` | Gets the current C# closure to access upvalues. |

---

### `LuaTable` — Lua table (hash + array)

Sealed class implementing `IEnumerable<KeyValuePair<LuaValue, LuaValue>>`.

```csharp
public sealed class LuaTable : IEnumerable<KeyValuePair<LuaValue, LuaValue>>
```

#### Constructors

| Constructor | Description |
|-------------|-------------|
| `LuaTable()` | Empty table (8 array + 8 hash capacity). |
| `LuaTable(int arrayCapacity, int dictionaryCapacity)` | Pre-sized table. |

#### Indexer

| Member | Description |
|--------|-------------|
| `LuaValue this[LuaValue key] { get; set; }` | Table access. Lua arrays are 1-indexed. |

#### Properties

| Property | Description |
|----------|-------------|
| `int HashMapCount` | Number of non-nil hash entries. |
| `int ArrayLength` | Length of the array part (first nil or array bound). |
| `LuaTable? Metatable { get; set; }` | The table's metatable. |

#### Methods

| Method | Description |
|--------|-------------|
| `bool TryGetValue(LuaValue key, out LuaValue value)` | Safe lookup. |
| `bool ContainsKey(LuaValue key)` | Key existence check. |
| `LuaValue RemoveAt(int index)` | Removes from array part at 1-based index. |
| `void Insert(int index, LuaValue value)` | Inserts into array part at 1-based index. |
| `bool TryGetNext(LuaValue key, out KeyValuePair<LuaValue, LuaValue> pair)` | For `next()` iteration. |
| `void Clear()` | Clears all entries. |
| `Memory<LuaValue> GetArrayMemory()` | Raw array part as memory. |
| `Span<LuaValue> GetArraySpan()` | Raw array part as span. |
| `LuaTableEnumerator GetEnumerator()` | Custom struct enumerator (allocation-free). |

---

### `LuaStack` — Evaluation stack

```csharp
public sealed class LuaStack
```

| Member | Description |
|--------|-------------|
| `int Count` | Current stack height. |
| `LuaValue this[int index] { get; set; }` | Stack indexer. |
| `void EnsureCapacity(int newSize)` | Ensures stack capacity. |
| `void Push(LuaValue value)` | Pushes a value. |
| `void PushRange(ReadOnlySpan<LuaValue> values)` | Pushes multiple values. |
| `LuaValue Pop()` | Pops and returns one value. |
| `void Pop(int count)` | Pops N values. |
| `void PopUntil(int newSize)` | Pops until stack size reaches `newSize`. |
| `void Clear()` | Clears the stack. |
| `Span<LuaValue> AsSpan()` | Active portion of the stack. |
| `Span<LuaValue> GetBuffer()` | Entire underlying buffer. |
| `Memory<LuaValue> GetBufferMemory()` | Entire underlying buffer as memory. |

---

### `LuaStackReader` — Read-only stack view (disposable struct)

```csharp
public readonly struct LuaStackReader : IDisposable
```

| Member | Description |
|--------|-------------|
| `int Count` | Number of values. |
| `int Length` | Same as `Count`. |
| `LuaValue this[int index]` | Indexer. |
| `ReadOnlySpan<LuaValue> AsSpan()` | Values as a span. |
| `void Dispose()` | Pops values from the stack. |

---

### `LuaThreadStatus` — Coroutine status enum

```csharp
public enum LuaThreadStatus : byte
{
    Suspended,
    Normal,
    Running,
    Dead
}
```

---

### `ILuaUserData` — Userdata interface

```csharp
public interface ILuaUserData
{
    LuaTable? Metatable { get; set; }
    Span<LuaValue> UserValues { get; }
}
```

---

### `LuaModule` — Loaded module

```csharp
public readonly struct LuaModule
```

| Member | Description |
|--------|-------------|
| `string Name` | Module name. |
| `LuaModuleType Type` | `Text` or `Bytes`. |
| `ReadOnlySpan<char> ReadText()` | Read as text. |
| `ReadOnlySpan<byte> ReadBytes()` | Read as bytes. |

```csharp
public enum LuaModuleType { Text, Bytes }
```

---

### `ILuaModuleLoader` — Custom module loader

```csharp
public interface ILuaModuleLoader
{
    bool Exists(string moduleName);
    ValueTask<LuaModule> LoadAsync(string moduleName, CancellationToken cancellationToken = default);
}
```

---

## Namespace: `Lua.StateExtensions`

### `LuaStateExtensions` — Convenience methods (extension methods on `LuaState`)

#### Load & Execute

| Method | Description |
|--------|-------------|
| `Task<LuaValue[]> DoStringAsync(this LuaState state, string source, string? chunkName = null, CancellationToken ct = default)` | Compile and run a Lua string. Returns result array. |
| `Task DoStringAsync(this LuaState state, string source, Memory<LuaValue> results, string? chunkName = null, CancellationToken ct = default)` | Compile and run; writes results to a pre-allocated buffer. |
| `Task<LuaValue[]> DoFileAsync(this LuaState state, string path, CancellationToken ct = default)` | Load and run a file. Returns result array. |
| `Task DoFileAsync(this LuaState state, string path, Memory<LuaValue> buffer, CancellationToken ct = default)` | Load and run; writes results to a pre-allocated buffer. |
| `Task<LuaValue[]> ExecuteAsync(this LuaState state, ReadOnlySpan<byte> source, string chunkName, CancellationToken ct = default)` | Execute bytecode or text bytes. |
| `Task ExecuteAsync(this LuaState state, ReadOnlySpan<byte> source, Memory<LuaValue> results, string chunkName, CancellationToken ct = default)` | Execute bytes with result buffer. |
| `Task<LuaValue[]> ExecuteAsync(this LuaState state, LuaClosure closure, CancellationToken ct = default)` | Execute a compiled closure. |
| `Task ExecuteAsync(this LuaState state, LuaClosure closure, Memory<LuaValue> buffer, CancellationToken ct = default)` | Execute a closure with result buffer. |
| `ValueTask<LuaClosure> LoadFileAsync(this LuaState state, string fileName, string mode = "bt", LuaTable? environment = null, CancellationToken ct = default)` | Load a file into a `LuaClosure`. |

#### Stack Operations

| Method | Description |
|--------|-------------|
| `static void Push(this LuaState state, LuaValue value)` | Push a single value. |
| `static void Push(this LuaState state, ReadOnlySpan<LuaValue> values)` | Push multiple values. |
| `static LuaValue Pop(this LuaState state)` | Pop one value. |
| `static void Pop(this LuaState state, int count)` | Pop N values. |
| `static LuaStackReader ReadStack(this LuaState state, int count)` | Read `count` values from the top of the stack (disposable). |

#### Metamethod-Aware Operations

| Method | Description |
|--------|-------------|
| `ValueTask<LuaValue> AddAsync(this LuaState state, LuaValue x, LuaValue y, CancellationToken ct = default)` | `x + y` with `__add` fallback. |
| `ValueTask<LuaValue> SubAsync(...)` | `x - y` with `__sub`. |
| `ValueTask<LuaValue> MulAsync(...)` | `x * y` with `__mul`. |
| `ValueTask<LuaValue> DivAsync(...)` | `x / y` with `__div`. |
| `ValueTask<LuaValue> ModAsync(...)` | `x % y` with `__mod`. |
| `ValueTask<LuaValue> PowAsync(...)` | `x ^ y` with `__pow`. |
| `ValueTask<LuaValue> UnmAsync(...)` | `-x` with `__unm`. |
| `ValueTask<LuaValue> LenAsync(...)` | `#x` with `__len`. |
| `ValueTask<LuaValue> ConcatAsync(this LuaState state, ReadOnlySpan<LuaValue> values, CancellationToken ct = default)` | `x1 .. x2 .. ...` with `__concat`. |
| `ValueTask<LuaValue> ConcatAsync(this LuaState state, int concatCount, CancellationToken ct = default)` | Concatenates top N stack values. |
| `ValueTask<bool> LessThanAsync(...)` | `x < y` with `__lt`. |
| `ValueTask<bool> LessThanOrEqualsAsync(...)` | `x <= y` with `__le`. |
| `ValueTask<bool> EqualsAsync(...)` | `x == y` with `__eq`. |
| `ValueTask<LuaValue> GetTableAsync(this LuaState state, LuaValue table, LuaValue key, CancellationToken ct = default)` | `table[key]` with `__index`. |
| `ValueTask SetTableAsync(this LuaState state, LuaValue table, LuaValue key, LuaValue value, CancellationToken ct = default)` | `table[key] = value` with `__newindex`. |

#### Calling Functions

| Method | Description |
|--------|-------------|
| `ValueTask<int> CallAsync(this LuaState state, int funcIndex, CancellationToken ct = default)` | Call function at stack position `funcIndex`. |
| `ValueTask<int> CallAsync(this LuaState state, int funcIndex, int returnBase, CancellationToken ct = default)` | Call with explicit return base. |
| `ValueTask<LuaValue[]> CallAsync(this LuaState state, LuaValue function, ReadOnlySpan<LuaValue> arguments, CancellationToken ct = default)` | Call a function value with argument span. |

---

## Namespace: `Lua.Standard`

### `OpenLibsExtensions` — Standard library registration

Extension methods on `LuaState`. Each method adds the corresponding Lua standard library to the global environment.

| Method | Adds |
|--------|------|
| `void OpenBasicLibrary(this LuaState)` | `print`, `assert`, `dofile`, `error`, `getmetatable`, `ipairs`, `loadfile`, `load`, `next`, `pairs`, `pcall`, `rawequal`, `rawget`, `rawlen`, `rawset`, `select`, `setmetatable`, `tonumber`, `tostring`, `type`, `xpcall`, `_G`, `_VERSION` |
| `void OpenBitwiseLibrary(this LuaState)` | `bit32` table with all bitwise functions |
| `void OpenCoroutineLibrary(this LuaState)` | `coroutine` table (`create`, `resume`, `running`, `status`, `wrap`, `yield`) |
| `void OpenIOLibrary(this LuaState)` | `io` table (`close`, `flush`, `input`, `lines`, `open`, `output`, `read`, `type`, `write`, `tmpfile`) |
| `void OpenMathLibrary(this LuaState)` | `math` table (all math functions), `math.pi`, `math.huge` |
| `void OpenModuleLibrary(this LuaState)` | `package` table (`loaded`, `preload`, `searchers`, `path`, `searchpath`, `config`), global `require` |
| `void OpenOperatingSystemLibrary(this LuaState)` | `os` table (`clock`, `date`, `difftime`, `execute`, `exit`, `getenv`, `remove`, `rename`, `setlocale`, `time`, `tmpname`) |
| `void OpenStringLibrary(this LuaState)` | `string` table (`byte`, `char`, `dump`, `find`, `format`, `gmatch`, `gsub`, `len`, `lower`, `match`, `rep`, `reverse`, `sub`, `upper`), `string` metatable `__index` |
| `void OpenTableLibrary(this LuaState)` | `table` table (`concat`, `insert`, `pack`, `remove`, `sort`, `unpack`) |
| `void OpenDebugLibrary(this LuaState)` | `debug` table (`getlocal`, `setlocal`, `getupvalue`, `setupvalue`, `getmetatable`, `setmetatable`, `getuservalue`, `setuservalue`, `traceback`, `getregistry`, `upvalueid`, `upvaluejoin`, `gethook`, `sethook`, `getinfo`) |
| `void OpenStandardLibraries(this LuaState)` | Opens all 11 libraries at once. |

### `LibraryFunction` — Function descriptor

```csharp
public readonly record struct LibraryFunction(string Name, LuaFunction Func)
{
    public LibraryFunction(string libraryName, string name, Func<LuaFunctionExecutionContext, CancellationToken, ValueTask<int>> function);
}
```

### `FileHandle` — IO file handle (implements `ILuaUserData`)

```csharp
public sealed class FileHandle : ILuaUserData
```

| Member | Description |
|--------|-------------|
| `bool IsOpen` | Whether the file is open. |
| `FileHandle(Stream stream, LuaFileOpenMode mode)` | Wraps a .NET `Stream`. |
| `FileHandle(ILuaStream stream)` | Wraps an `ILuaStream`. |
| `ValueTask<double?> ReadNumberAsync(CancellationToken ct = default)` | Reads a numeric value. |
| `ValueTask<string?> ReadLineAsync(bool keepEol, CancellationToken ct = default)` | Reads one line. |
| `ValueTask<string> ReadToEndAsync(CancellationToken ct = default)` | Reads all remaining text. |
| `ValueTask<string?> ReadStringAsync(int count, CancellationToken ct = default)` | Reads `count` characters. |
| `ValueTask WriteAsync(string content, CancellationToken ct = default)` | Writes a string. |
| `ValueTask WriteAsync(ReadOnlyMemory<char> content, CancellationToken ct = default)` | Writes a character memory. |
| `long Seek(string whence, long offset)` | Seeks: `"set"`, `"cur"`, or `"end"`. |
| `ValueTask FlushAsync(CancellationToken ct = default)` | Flushes buffers. |
| `void SetVBuf(string mode, int size)` | Sets buffering: `"no"`, `"full"`, or `"line"`. |
| `ValueTask Close(CancellationToken ct = default)` | Closes the file handle. |

---

## Namespace: `Lua.Runtime`

### `LuaClosure` — Compiled Lua function

```csharp
public sealed class LuaClosure : LuaFunction
```

| Member | Description |
|--------|-------------|
| `LuaClosure(LuaState state, Prototype proto, LuaTable? environment = null)` | Create from a compiled prototype. |
| `Prototype Proto` | The compiled bytecode prototype. |
| `ReadOnlySpan<UpValue> UpValues` | The closure's upvalues. |

### `CSharpClosure` — C# function with upvalues

```csharp
public sealed class CSharpClosure : LuaFunction
```

| Member | Description |
|--------|-------------|
| `CSharpClosure(string name, LuaValue[] upValues, Func<LuaFunctionExecutionContext, CancellationToken, ValueTask<int>> func)` | Create with upvalues. |
| `LuaValue[] UpValues` | Read/write upvalues by index. |

### `Prototype` — Compiled bytecode chunk

```csharp
public sealed class Prototype
```

| Member | Description |
|--------|-------------|
| `ReadOnlySpan<LuaValue> Constants` | Constant pool. |
| `ReadOnlySpan<Instruction> Code` | Bytecode instructions. |
| `ReadOnlySpan<Prototype> ChildPrototypes` | Nested function prototypes. |
| `ReadOnlySpan<int> LineInfo` | Line number mapping. |
| `ReadOnlySpan<LocalVariable> LocalVariables` | Local variable debug info. |
| `ReadOnlySpan<UpValueDesc> UpValues` | Upvalue metadata. |
| `string ChunkName` | Source chunk name. |
| `int LineDefined` / `int LastLineDefined` | Function definition line range. |
| `int ParameterCount` / `int MaxStackSize` | Function signature. |
| `bool HasVariableArguments` | Whether the function has varargs (`...`). |
| `static ReadOnlySpan<byte> LuaBytecodeSignature` | The `\x1bLua` signature bytes. |
| `static Prototype FromBytecode(ReadOnlySpan<byte> span, ReadOnlySpan<char> name)` | Deserialize from bytecode. |
| `byte[] ToBytecode(bool useLittleEndian = true)` | Serialize to byte array. |
| `void WriteBytecode(IBufferWriter<byte> bufferWriter, bool useLittleEndian = true)` | Serialize to a writer. |

### `Instruction` — VM instruction

```csharp
public readonly partial struct Instruction
```

| Member | Description |
|--------|-------------|
| `uint Value` | Raw instruction bits. |
| `OpCode OpCode { get; set; }` | The opcode. |
| `int A / B / C / Bx / Ax / SBx { get; set; }` | Instruction operand fields. |

Static factory methods for every opcode: `Instruction.Move(a, b, c)`, `Instruction.LoadK(a, bx)`, etc.

### `OpCode` — VM opcode enum

```
Move, LoadK, LoadKX, LoadBool, LoadNil, GetUpVal, GetTabUp, GetTable,
SetTabUp, SetUpVal, SetTable, NewTable, Self, Add, Sub, Mul, Div, Mod,
Pow, Unm, Not, Len, Concat, Jmp, Eq, Lt, Le, Test, TestSet, Call,
TailCall, Return, ForLoop, ForPrep, TForCall, TForLoop, SetList, Closure,
VarArg, ExtraArg
```

### `CallStackFrame` — Stack frame info

```csharp
public readonly record struct CallStackFrame
```

| Member | Description |
|--------|-------------|
| `int Base` | Stack base for this function. |
| `int ReturnBase` | Frame base to return to. |
| `LuaFunction Function` | The executing function. |
| `int VariableArgumentCount` | Vararg count. |
| `int CallerInstructionIndex` | Return instruction index. |
| `int Version` | Frame version (for closure validity checks). |

### `UpValue` — Closure upvalue

```csharp
public sealed class UpValue
```

| Member | Description |
|--------|-------------|
| `LuaState? Thread` | Owning thread (open) or null (closed). |
| `bool IsClosed` | Whether the upvalue has been closed. |
| `int RegisterIndex` | Stack register index (for open upvalues). |
| `static UpValue Open(LuaState state, int registerIndex)` | Creates an open upvalue. |
| `static UpValue Closed(LuaValue value)` | Creates a closed upvalue. |
| `LuaValue GetValue()` | Reads the current value. |
| `void SetValue(LuaValue value)` | Sets the value. |
| `void Close()` | Closes the upvalue (copies stack value). |

### `Traceback` — Stack traceback

```csharp
public readonly record struct Traceback
```

| Member | Description |
|--------|-------------|
| `LuaState State` | The state the traceback was taken from. |
| `LuaFunction RootFunc` | The root function. |
| `ReadOnlySpan<CallStackFrame> StackFrames` | All stack frames. |
| `int LastLine / FirstLine` | Source line range. |
| `string ToString(int skipFrames = 0)` | Formats as a Lua traceback string. |
| `static string CreateTracebackMessage(LuaState state, LuaValue message, int stackFramesSkipCount = 0)` | Creates a formatted error message with traceback. |

### `Metamethods` — Metamethod string constants

```csharp
public static class Metamethods
{
    public const string Metatable = "__metatable";
    public const string Index = "__index";
    public const string NewIndex = "__newindex";
    public const string Add = "__add";
    public const string Sub = "__sub";
    // ... all standard metamethods
}
```

---

## Namespace: `Lua.Platforms`

### `LuaPlatform` — Platform abstraction record

```csharp
public record LuaPlatform(
    ILuaFileSystem FileSystem,
    ILuaOsEnvironment OsEnvironment,
    ILuaStandardIO StandardIO,
    TimeProvider TimeProvider
);
```

Used for sandboxing, custom I/O, and environment abstraction.

### `ILuaOsEnvironment` — OS environment interface

```csharp
public interface ILuaOsEnvironment
{
    string? GetEnvironmentVariable(string name);
    ValueTask Exit(int exitCode, CancellationToken ct);
    double GetTotalProcessorTime();
}
```

---

## Namespace: `Lua.IO`

### `ILuaStream` — Lua file stream

```csharp
public interface ILuaStream
```

| Member | Description |
|--------|-------------|
| `bool IsOpen` | Whether the stream is open. |
| `LuaFileOpenMode Mode` | The file open mode. |
| `ValueTask<string> ReadAllAsync(CancellationToken ct = default)` | Reads all content. |
| `ValueTask<double?> ReadNumberAsync(CancellationToken ct = default)` | Reads a numeric token. |
| `ValueTask<string?> ReadLineAsync(bool keepEol, CancellationToken ct = default)` | Reads one line. |
| `ValueTask<string?> ReadAsync(int count, CancellationToken ct = default)` | Reads `count` characters. |
| `ValueTask WriteAsync(ReadOnlyMemory<char> content, CancellationToken ct = default)` | Writes text. |
| `ValueTask WriteAsync(string content, CancellationToken ct = default)` | Writes a string. |
| `ValueTask FlushAsync(CancellationToken ct = default)` | Flushes buffers. |
| `void SetVBuf(LuaFileBufferingMode mode, int size)` | Sets buffering mode. |
| `long Seek(SeekOrigin origin, long offset)` | Seeks to a position. |
| `ValueTask CloseAsync(CancellationToken ct = default)` | Closes the stream. |
| `static ILuaStream CreateFromStream(Stream stream, LuaFileOpenMode openMode)` | Wraps a .NET `Stream`. |
| `static ILuaStream CreateFromString(string content)` | Creates a readable stream from a string. |
| `static ILuaStream CreateFromMemory(ReadOnlyMemory<char> content)` | Creates a readable stream from memory. |

### `ILuaByteStream` — Byte-level stream

```csharp
public interface ILuaByteStream
{
    ValueTask<int> ReadByteAsync(CancellationToken ct = default);
    ValueTask ReadBytesAsync(IBufferWriter<byte> writer, CancellationToken ct = default);
}
```

### `ILuaStandardIO` — Standard I/O

```csharp
public interface ILuaStandardIO
{
    ILuaStream Input { get; }
    ILuaStream Output { get; }
    ILuaStream Error { get; }
}
```

### `ILuaFileSystem` — File system abstraction

```csharp
public interface ILuaFileSystem
{
    bool IsReadable(string path);
    ValueTask<ILuaStream> Open(string path, LuaFileOpenMode mode, CancellationToken ct = default);
    ValueTask Rename(string oldName, string newName, CancellationToken ct = default);
    ValueTask Remove(string path, CancellationToken ct = default);
    string DirectorySeparator { get; }
    string GetTempFileName();
    ValueTask<ILuaStream> OpenTempFileStream(CancellationToken ct = default);
}
```

### `ILuaFileLoader` — File loader

```csharp
public interface ILuaFileLoader
{
    bool Exists(string path);
    ValueTask<ILuaStream> LoadAsync(string path, CancellationToken ct = default);
}
```

### `LuaStream` — Concrete stream (ILuaStream + ILuaByteStream)

```
LuaStream(LuaFileOpenMode mode, Stream innerStream)
```

### `LuaFileOpenMode` — File mode enum

```csharp
public enum LuaFileOpenMode { Read, Write, Append, ReadUpdate, WriteUpdate, AppendUpdate }
```

### `LuaFileBufferingMode` — Buffering mode enum

```csharp
public enum LuaFileBufferingMode { FullBuffering, LineBuffering, NoBuffering }
```

### `CompositeLoaderFileSystem` — Composite file system

Combines multiple `ILuaFileLoader` instances with an optional fallback `ILuaFileSystem`.

```csharp
public sealed class CompositeLoaderFileSystem : ILuaFileSystem
{
    public CompositeLoaderFileSystem(ILuaFileLoader[] loaders, ILuaFileSystem? system = null);
    public static CompositeLoaderFileSystem Create(ILuaFileSystem system, params ILuaFileLoader[] loaders);
    public static CompositeLoaderFileSystem Create(params ILuaFileLoader[] loaders);
}
```

---

## Namespace: `Lua.Loaders`

### `CompositeModuleLoader` — Combine multiple module loaders

```csharp
public static class CompositeModuleLoader
{
    public static ILuaModuleLoader Create(params ILuaModuleLoader[] loaders);
    // Overloads for 2–6 loaders
}
```

---

## Namespace: `Lua.CodeAnalysis`

### `SourcePosition` — Position in source

```csharp
public readonly record struct SourcePosition(int Line, int Column)
```

### `LocalVariable` — Local variable debug info

```csharp
public readonly record struct LocalVariable(string Name, int StartPc, int EndPc)
```

### `UpValueDesc` — Upvalue descriptor

```csharp
public readonly record struct UpValueDesc(string Name, bool IsLocal, int Index)
```

---

## Exception Types (namespace `Lua`)

| Exception | Description |
|-----------|-------------|
| `LuaParseException` | Thrown on syntax errors during parsing. Contains `ChunkName` and `Position`. |
| `LuaCompileException` | Thrown during code compilation. Contains `ChunkName`, `OffSet`, `Position`, and `NearToken`. |
| `LuaUndumpException` | Thrown when deserializing invalid binary bytecode. |
| `LuaRuntimeException` | Thrown on runtime errors. Contains `ErrorObject` and optional `LuaTraceback`. |
| `LuaAssertionException` | Thrown by `assert()`. Inherits `LuaRuntimeException`. |
| `LuaModuleNotFoundException` | Thrown when `require()` cannot find a module. |
| `LuaCanceledException` | Thrown on cancellation during execution. Inherits `OperationCanceledException`. |

---

## Source Generator Attributes (namespace `Lua`, assembly `Lua.Annotations`)

| Attribute | Target | Description |
|-----------|--------|-------------|
| `[LuaObject]` / `[LuaObject(string name)]` | `partial class` | Generates Lua interop wrappers. Optional name overrides the type name in Lua. |
| `[LuaMember]` / `[LuaMember(string name)]` | Method, field, property | Includes a member in the generated Lua API. Optional name renames the member. |
| `[LuaMetamethod(LuaObjectMetamethod)]` | Method | Maps a C# method to a Lua metamethod (`__add`, `__sub`, etc.). |
| `[LuaIgnoreMember]` | Member | Excludes a member from the generated Lua API. |

### `LuaObjectMetamethod` enum

```
Add, Sub, Mul, Div, Mod, Pow, Unm, Len, Eq, Lt, Le, Call, Concat,
Pairs, IPairs, ToString, Index, NewIndex
```

> Note: `Index` and `NewIndex` cannot be set — they are used internally by the generated code.

---

## Type Mapping: Lua ↔ C#

| Lua Value | LuaValueType | C# Type | Read via |
|-----------|-------------|---------|----------|
| `nil` | `Nil` | — | `type == LuaValueType.Nil` |
| `boolean` | `Boolean` | `bool` | `Read<bool>()` |
| `number` | `Number` | `double`, `float`, `int` | `Read<double>()` |
| `string` | `String` | `string` | `Read<string>()` |
| `table` | `Table` | `LuaTable` | `Read<LuaTable>()` |
| `function` | `Function` | `LuaFunction` | `Read<LuaFunction>()` |
| `thread` | `Thread` | `LuaState` | `Read<LuaState>()` |
| `userdata` | `UserData` | `ILuaUserData` | `Read<ILuaUserData>()` |
| (light) userdata | `LightUserData` | `object` | `Read<object>()` |
