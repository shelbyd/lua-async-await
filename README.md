# lua-async-await

Inspired by [this library](https://github.com/ms-jpq/lua-async-await), lua-async-await uses lua coroutines to add async/await-like syntax to lua. The aim is to be easily importable into other projects (low LOC) and simple to work with.

It is also fully test-driven, so should be correct and your case should be easily tested if incorrect.

## Usage

```lua
local a = require("lua-async-await")

-- Return values from a.sync functions.
local greet = a.sync(function()
  return "Hello"
end)

-- You can also use wrap to use nodejs style callbacks.
local separator = a.wrap(function(cb)
  cb(", ")
end)

local main = a.sync(function(name)
  local g = a.wait(greet())
  local s = a.wait(separator())
  return g .. s .. name
end)

main("World")
```

### Combinators

`a.wait_all` runs all the provided expressions in parallel and returns the result of each when the last finishes.

```lua
local just = a.sync(function(x)
  return x
end)

local one, two, three = a.wait_all(just(1), just(2), just(3))
```

`a.wait_race` returns the first expression to complete. The others continue to run but their output is dropped.

```lua
local fast = a.sync(function()
  return "fast"
end)
local slow = a.sync(function()
  a.wait(sleep_somehow(1000))
  return "slow"
end)

local result = a.wait_race(fast(), slow())
assert(result[1] == "fast")
assert(result[2] == nil)
```
