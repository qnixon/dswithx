A recursive function, `choose`, walks the plants in order. At each plant it
calls itself twice: once taking the plant into the compost group and once
skipping it. When it has taken 8, it counts the split. It's declared with
`local function`, which lets it call itself; `local choose = function`
would fail, because the name isn't in scope yet inside the body.

`tonumber("459")` gives an integer, so the totals and the `>=` test stay
exact. Lua's `/` always returns a float, even for 8 / 4, which is what the
means want. LuaRocks isn't installed.
