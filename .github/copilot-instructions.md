- This is a prototype of a game. More info about the game and implementation plan is in `README.md`
- Logs of the latest run are piped to `logs.txt`. ALWAYS check the logs first.
  - Errors typically look like this `[ERROR 00:57:42]`
- There is a strong emphasis on decoupled code and data-oriented design.
  - Components should not know about each other until used in a system.
  - Components data should only be simple data. Avoid nested tables in components.
- `require` calls
  - always placed at the top of the file
  - global requires come first before non-global requires
  - global requires must be added to `Lua.diagnostics.global` array in settings
- This project uses Love2D 11.5. Documentation is located here: https://love2d.org/wiki/love
- You must AVOID these things:
  - Using timers/grace periods/cooldowns to fix bugs.
  - Adding logs that will print frequently (every frame)
- When calling Love2D methods in a process/draw/render method (gets called every frame), it's best to put the method in a local variable at the top of the file. Example:
- If there appears to be a missing function call, first check `main.lua` to see if it is present there.
- The entire Love2D documentation can be found in this page: https://love2d-community.github.io/love-api/
- Do not modify files in the `assets` folder, but let the user know if there is a potential issue in the folder.
- If there is an aseprite rendering issue check:
  - That the spritesheet json is exported in ARRAY mode and NOT HASH mode

```lua
local somelibrary = require 'somelibrary'

local translate = love.graphics.translate

func draw()
  translate(50, 50)
end
```
