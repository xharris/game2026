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

- Enemy AI state machine (`idle`, `patrol`, `chase`)
- Patrol behavior (random or waypoint)
- Chase behavior
- Raycasting / LOS using bump (`querySegment` or thin sweep)
- Debug AI state + rays

---

**Day 4**

- Chunk image format (walls, spawns, magic)
- Chunk loader (image → tiles, walls, spawns)
- World chunk enter / exit logic
- Simple procedural map layout (grid / random walk)
- Room transitions

---

**Day 5**

- Magic system (data-driven)
- Status effects on entities
- Magic sources in chunks
- Magic-modified projectiles (fire, water, etc.)
- Damage-over-time / on-hit effects

---

**Day 6**

- Puzzle chunk (pressure plate, clear-room, or trigger)
- Boss chunk
- Boss enemy (more HP, extra AI state)
- Chunk locking / unlocking logic

---

**Day 7**

- Wall lighting polish (cheap gradients / edge highlights)
- Balance pass (enemy speed, damage, magic)
- Visual feedback (hit flashes, death effects)
- Bug fixing
- Playtest + cut anything that doesn’t work

---

### Guiding Rule for the Week

> **If a feature doesn’t clearly improve “move → shoot → room → enemy → reward”, cut it.**
