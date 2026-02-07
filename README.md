# DESIGN

## Entity

```lua
entity = {
    pos = {vector},
    vel = {vector},
    ase = {image, json, animation, loop}, -- always center image
    body = {shape},
    hitbox = {shape},
    hurtbox = {shape},
    hp = 10,
    aim_dir = {vector}, -- normalized
    magic_effects = {magic.type...},
    ai = {state='patrol', time_left=0},
    controller_id = 1
}
```

### Collisions: hitbox, hurtbox, body

- signals for responses

### Magic effects

```lua
magic = {
    type = 'fire',
    duration = 3,
    ticks = 2,
    -- happens every (duration / ticks) seconds
    apply = function(target, source)
        -- do damage
        -- slight knockback in random dir
    end
}
```

## Map

- generated from image pixels

- chunk
  - each pixel is a tile: blank, filler, path, wall, enemy spawn, magic source
- map
  - 2 colors: empty, chunk
  - auto-fill 'chunk' with chunks (restricted wfc)

### polish

- wall lighting

## GPT: When ECS _Would_ Make Sense

Only consider ECS if:

- You continue past prototype
- You have >50 entity types
- You need heavy systemic interactions

If you reach that point, you can **refactor gradually**.

---

# PLAN

## One-Week Survival Plan

**Day 1**

- [x] Project skeleton (`world`, `entity`, `player`)
- [x] Player movement (top-down)
- [x] Twin-stick aiming (mouse or stick)
- [x] Basic shooting (projectiles)
- [x] Wall collision using `body` collider (bump)

---

**Day 2**

- [x] Projectile → hurtbox damage
- [x] Enemy entity
- [x] Enemy HP + death
- [x] Basic knockback on hit
- [x] Cleanup on enemy death

---

**Day 3**

- [x] Enemy AI state machine (`idle`, `patrol`, `chase`)
  - [x] Patrol behavior
    - [x] random
    - [ ] waypoints
  - [x] Chase behavior
    - [x] Raycasting / LOS using bump (`querySegment` or thin sweep)
- [x] Debug AI state + rays

---

**Day 4**

- [x] Camera system
- [x] Map
  - zone
  - special, can be used for puzzles or whatever
    - pressure plate
    - box
    - box with key
    - door
    - etc
  - Config
    - zone image
    - chunks
    - connections: possible connecting zones
- [x] Load/Activate zone when nearby
- Tiles
  - [x] Enemy spawn
  - [x] Filler
- [x] Water background color

---

**Day 5**

- [x] Magic system (data-driven)
- [x] Status effects on entities
- [x] Special map tile: campfire
- [x] Point at magic source
  - [ ] source goes on longish cooldown?
- [x] Magic-modified projectiles (fire, water, etc.)
- [x] Damage-over-time / on-hit effects
- [ ] Checkpoint: save location
- [ ] Respawn
  - [ ] Red death screen
  - [ ] Move player to checkpoint
  - [ ] Remove enemies too close to checkpoint? or put chase on cooldown
  - [ ] Extreme zoom out of player on spawn

---

**Day 6**

- Puzzle chunk (pressure plate, clear-room, or trigger)
- Boss chunk
- Boss enemy (more HP, extra AI state)
- Chunk locking / unlocking logic

---

**Day 7**

- Maps
  - [x] Forest
  - [ ] Dark Forest
- Wall lighting polish (cheap gradients / edge highlights)
- Balance pass (enemy speed, damage, magic)
- Visual feedback (hit flashes, death effects)
- Bug fixing
- Playtest + cut anything that doesn’t work
- Culling

---

### Guiding Rule for the Week

> **If a feature doesn’t clearly improve “move → shoot → room → enemy → reward”, cut it.**

## Resources

- datamoshing
  - https://www.reddit.com/r/godot/comments/1buubf1/datamoshing_compositor_effect_for_godot_43/
  - https://github.com/GODPUS/shaders/blob/master/datamosh/glsl/datamosh.glsl
- [water shader](https://www.cyanilux.com/tutorials/2d-water-shader-breakdown/)

## SFX

https://sfbgames.itch.io/chiptone

```
eJxjYpBWlxBRYDkjwwAFDfWejGsF-iLD-P7Xh_owCXNCBGvznYRBdKX1SU4wnb1OHER3O0Pk55tD6KkhEJrhC0NgliODlA8TE_NUNpBIBeMdMRDNulQDosRSX5cXrLRBFCIwUxJCX4Y6xBZo01TbQ3Zt6RD-WSYI_R8C5WdEMtATAAABqTBG
```
