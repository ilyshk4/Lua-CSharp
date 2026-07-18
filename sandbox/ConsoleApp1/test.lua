-- Static methods
local path = cs('System.IO.Path')
local name = path.GetFileNameWithoutExtension('test.txt')
print('GetFileNameWithoutExtension:', name)

local combined = path.Combine('hello', 'world')
print('Combine:', combined)

-- Instance methods with colon syntax
local sb = cs('System.Text.StringBuilder')()
sb:Append('hello ')
sb:Append('world')
print('StringBuilder:', sb.ToString())

-- Instance methods with dot syntax
local sb2 = cs('System.Text.StringBuilder')()
sb2.Append('direct')
print('Direct call:', sb2.ToString())

-- Static properties
local now = cs('System.DateTime').UtcNow
print('UtcNow:', now.ToString())

-- Constructor with arguments
local ts = cs('System.TimeSpan')(10000000)  -- 1 second
print('TimeSpan:', ts.TotalSeconds, 'seconds')

-- String operations
local str = cs('System.String')
local replaced = str.Replace('hello world', 'world', 'lua')
print('Replace:', replaced)

-- Math
local mathType = cs('System.Math')
local max = mathType.Max(42, 100)
print('Max:', max)
local pi = mathType.PI
print('PI:', pi)

print('All tests passed!')
