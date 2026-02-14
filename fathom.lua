-- Fathom
-- Dark Ambient Generator
-- v1.5 @Slab
--
-- "In the fathomless depths,
-- sound becomes texture, and
-- silence becomes presence."
--
-- Generative dark ambient
-- soundscapes inspired by
-- the deep ocean abyss
--
-- ENC1: Scroll menu
-- ENC2: Adjust value
-- ENC3: Depth (reverb/tension)
-- KEY2: Play/Stop
-- KEY3: Tap=Randomize
--       Hold=Menu toggle
--
-- GRID (optional):
-- Bottom-left: Play/Stop
-- Bottom-right: Randomize
--
-- ARC (optional):
-- Ring 1: Root Note
-- Ring 2: Density
-- Ring 3: Reverb Mix
-- Ring 4: Filter Cutoff

engine.name = "Fathom"

local MusicUtil = require "musicutil"
local UI = require "ui"

-- State variables
local playing = false
local clock_id
local depth = 0  -- User-controllable depth (affects reverb/tension)
local visual_depth = 0  -- Visual indicator only
local drift = 0
local current_note = 60
local last_update = 0

-- Menu system
local show_menu = false  -- Start with menu hidden
local menu_scroll = 0
local menu_cursor = 0  -- Current selection position (0-based)
local menu_items = {}
local items_per_page = 5
local randomize_message = ""
local randomize_timer = 0
local key3_time = 0
local long_press_threshold = 0.5

-- Generative parameters
local params_list = {}
local current_param = 1

-- Scales
local scales = {
  "Minor", "Phrygian", "Locrian", "Harmonic Minor",
  "Dorian", "Minor Pentatonic", "Whole Tone"
}

-- Visual state
local particles = {}
local wave_offset = 0
local creature_x = 64
local creature_timer = 0
local bioluminescence = {}

-- MIDI setup
local midi_device
local midi_channel = 1

-- Grid setup
local g = grid.connect()
local grid_dirty = true

-- Arc setup
local a = arc.connect()
local arc_dirty = true

-- Initialize particles for visual effect
local function init_particles()
  particles = {}
  for i = 1, 25 do
    table.insert(particles, {
      x = math.random(0, 128),
      y = math.random(0, 64),
      speed = math.random(1, 3) / 50, -- Much slower (was /10)
      size = math.random(1, 2),
      brightness = math.random(3, 8)
    })
  end
end

-- Initialize bioluminescence
local function init_bioluminescence()
  bioluminescence = {}
  for i = 1, 8 do
    table.insert(bioluminescence, {
      x = math.random(10, 118),
      y = math.random(10, 54),
      radius = 0,
      max_radius = math.random(8, 20),
      phase = 0,  -- Start at 0, not random
      speed = math.random(3, 6) / 500,  -- Speed of expansion
      active = false  -- Not active until triggered
    })
  end
end

-- Trigger a bioluminescent pulse
local function trigger_bioluminescence()
  -- Find an inactive ring and activate it
  for _, bio in ipairs(bioluminescence) do
    if not bio.active then
      bio.active = true
      bio.phase = 0
      bio.x = math.random(10, 118)  -- New random position
      bio.y = math.random(10, 54)
      bio.max_radius = math.random(8, 20)  -- New random size
      break  -- Only trigger one ring per note
    end
  end
end

-- Generate note based on current parameters
local function generate_note()
  local root = params:get("root_note")
  local scale_type = params:get("scale")
  local octave_range = params:get("octave_range")
  local tension = params:get("tension")
  
  -- Get scale notes
  local scale_notes = MusicUtil.generate_scale(root, scales[scale_type], octave_range)
  
  -- Choose note based on tension (lower tension = more repetition)
  local note_index
  if math.random() < (1 - tension / 100) then
    -- Stay near current note
    local current_index = 1
    for i, note in ipairs(scale_notes) do
      if note == current_note then
        current_index = i
        break
      end
    end
    note_index = math.max(1, math.min(#scale_notes, 
      current_index + math.random(-2, 2)))
  else
    -- Jump to new note
    note_index = math.random(1, #scale_notes)
  end
  
  current_note = scale_notes[note_index]
  return current_note
end

-- Generate and play note
local function play_generative_note()
  if not playing then return end
  
  local note = generate_note()
  local velocity = math.random(40, 80)
  local duration = params:get("note_duration")
  
  -- Play internal engine
  local amp = params:get("amp") / 100
  engine.noteOn(note, velocity / 127 * amp)
  
  -- Trigger bioluminescent ring
  trigger_bioluminescence()
  
  -- Send MIDI if enabled
  if params:get("midi_out") == 2 and midi_device then
    midi_device:note_on(note, velocity, midi_channel)
    clock.run(function()
      clock.sleep(duration * 0.8)
      midi_device:note_off(note, 0, midi_channel)
    end)
  end
  
  -- Update visual depth indicator (not the parameter)
  visual_depth = (visual_depth + math.random(5, 15)) % 64
  
  -- Trigger note off
  clock.run(function()
    clock.sleep(duration)
    engine.noteOff(note)
  end)
end

-- Main generative clock
local function generative_clock()
  while true do
    local interval = params:get("density") / 10
    clock.sync(interval)
    
    if playing then
      -- Randomly trigger notes based on probability
      if math.random() < params:get("probability") / 100 then
        play_generative_note()
      end
      
      -- Occasionally add textural layer
      if math.random() < 0.1 then
        engine.texture(math.random(30, 50))
      end
    end
  end
end

-- Randomize parameters
local function randomize_params()
  params:set("root_note", math.random(28, 48)) -- Lower range (was 36-60)
  params:set("scale", math.random(1, #scales))
  params:set("octave_range", math.random(1, 2)) -- Limit to 1-2 octaves (was 2-4)
  params:set("density", math.random(4, 12)) -- Slower, more sparse (was 2-8)
  params:set("tension", math.random(20, 60)) -- Lower tension for less movement (was 30-80)
  params:set("probability", math.random(40, 75)) -- More space/silence (was 50-95)
  params:set("note_duration", math.random(30, 80) / 10) -- Longer notes (3-8 sec)
  params:set("reverb_mix", math.random(60, 95))
  params:set("delay_time", math.random(4, 12) / 10)
  params:set("delay_feedback", math.random(40, 75))
  params:set("filter_freq", math.random(800, 2500)) -- Darker filter range
  
  -- Set visual feedback
  randomize_message = "PARAMETERS RANDOMIZED"
  randomize_timer = 2.0 -- Show message for 2 seconds
  
  print("Parameters randomized - Dark cinematic mode")
end

-- Initialize parameters
function init()
  -- ===== MUSICAL PARAMETERS (Key, Octave, Tempo) =====
  params:add_number("root_note", "Root Note", 24, 72, 40) -- Lower default (was 48)
  params:set_action("root_note", function(x)
    -- Action happens when value changes
  end)
  
  params:add_option("scale", "Scale", scales, 1)
  params:add_number("octave_range", "Octave Range", 1, 5, 2) -- Lower default (was 3)
  
  params:add_control("density", "Density", 
    controlspec.new(0.5, 16, 'lin', 0.5, 6, "beats")) -- Slower default (was 4)
  
  params:add_control("tension", "Tension", 
    controlspec.new(0, 100, 'lin', 1, 35, "%")) -- Lower tension (was 50)
  
  params:add_control("probability", "Probability", 
    controlspec.new(0, 100, 'lin', 1, 65, "%")) -- More sparse (was 80)
  
  params:add_control("note_duration", "Note Duration", 
    controlspec.new(0.1, 8, 'exp', 0.1, 4, "sec")) -- Longer default (was 2)
  
  -- ===== EFFECTS PARAMETERS =====
  params:add_control("reverb_mix", "Reverb Mix", 
    controlspec.new(0, 100, 'lin', 1, 60, "%"))
  params:set_action("reverb_mix", function(x)
    engine.reverbMix(x / 100)
  end)
  
  params:add_control("reverb_size", "Reverb Size", 
    controlspec.new(0, 100, 'lin', 1, 80, "%"))
  params:set_action("reverb_size", function(x)
    engine.reverbSize(x / 100)
  end)
  
  params:add_control("reverb_damp", "Reverb Damp", 
    controlspec.new(0, 100, 'lin', 1, 40, "%"))
  params:set_action("reverb_damp", function(x)
    engine.reverbDamp(x / 100)
  end)
  
  params:add_control("delay_time", "Delay Time", 
    controlspec.new(0.1, 2, 'exp', 0.01, 0.5, "sec"))
  params:set_action("delay_time", function(x)
    engine.delayTime(x)
  end)
  
  params:add_control("delay_feedback", "Delay Feedback", 
    controlspec.new(0, 95, 'lin', 1, 50, "%"))
  params:set_action("delay_feedback", function(x)
    engine.delayFeedback(x / 100)
  end)
  
  params:add_control("delay_mix", "Delay Mix", 
    controlspec.new(0, 100, 'lin', 1, 30, "%"))
  params:set_action("delay_mix", function(x)
    engine.delayMix(x / 100)
  end)
  
  -- ===== SYNTH ENGINE PARAMETERS =====
  params:add_control("filter_freq", "Filter Cutoff", 
    controlspec.new(100, 8000, 'exp', 1, 2000, "Hz"))
  params:set_action("filter_freq", function(x)
    engine.filterFreq(x)
  end)
  
  params:add_control("filter_res", "Filter Resonance", 
    controlspec.new(0, 100, 'lin', 1, 20, "%"))
  params:set_action("filter_res", function(x)
    engine.filterRes(x / 100)
  end)
  
  params:add_control("amp", "Amplitude", 
    controlspec.new(0, 100, 'lin', 1, 75, "%"))
  params:set_action("amp", function(x)
    engine.amp(x / 100)
  end)
  
  -- ===== OTHER PARAMETERS =====
  params:add_option("midi_out", "MIDI Out", {"Off", "On"}, 1)
  
  -- Initialize MIDI
  midi_device = midi.connect(1)
  
  -- Build menu items list - only include this script's parameters
  -- Get the starting index (first param we added)
  local script_params_start = params:lookup_param("root_note").id
  
  menu_items = {}
  for i = 1, params.count do
    local param = params:lookup_param(i)
    if param.id == "root_note" or 
       param.id == "scale" or
       param.id == "octave_range" or
       param.id == "density" or
       param.id == "tension" or
       param.id == "probability" or
       param.id == "note_duration" or
       param.id == "reverb_mix" or
       param.id == "reverb_size" or
       param.id == "reverb_damp" or
       param.id == "delay_time" or
       param.id == "delay_feedback" or
       param.id == "delay_mix" or
       param.id == "filter_freq" or
       param.id == "filter_res" or
       param.id == "amp" or
       param.id == "midi_out" then
      table.insert(menu_items, i)
    end
  end
  
  -- Initialize visuals
  init_particles()
  init_bioluminescence()
  
  -- Randomize on startup
  randomize_params()
  
  -- Start generative clock
  clock_id = clock.run(generative_clock)
  
  -- Start visual update
  clock.run(function()
    while true do
      clock.sleep(1/15)
      -- Count down randomize timer
      if randomize_timer > 0 then
        randomize_timer = randomize_timer - (1/15)
      end
      redraw()
      grid_redraw()
      -- Safely call arc_redraw
      pcall(arc_redraw)
    end
  end)
end

-- Key handlers
function key(n, z)
  if n == 2 and z == 1 then
    -- Play/Stop
    playing = not playing
    if playing then
      print("Fathom: Descending...")
    else
      print("Fathom: Surfacing...")
      engine.allNotesOff()
      if midi_device then
        for i = 0, 127 do
          midi_device:note_off(i, 0, midi_channel)
        end
      end
    end
    redraw()
  elseif n == 3 then
    if z == 1 then
      -- KEY3 pressed - record time
      key3_time = util.time()
    else
      -- KEY3 released - check if long press or short press
      local press_duration = util.time() - key3_time
      
      if press_duration >= long_press_threshold then
        -- Long press - toggle menu
        show_menu = not show_menu
        print(show_menu and "Menu shown" or "Menu hidden")
        redraw()
      else
        -- Short press - randomize
        randomize_params()
        -- Temporarily show menu so user can see changes
        local menu_was_hidden = not show_menu
        show_menu = true
        redraw()
        -- Hide menu again after a delay if it was hidden
        if menu_was_hidden then
          clock.run(function()
            clock.sleep(3)
            show_menu = false
            redraw()
          end)
        end
      end
    end
  end
end

-- Encoder handlers
function enc(n, d)
  if n == 1 then
    -- Move cursor through menu
    menu_cursor = util.clamp(menu_cursor + d, 0, #menu_items - 1)
    
    -- Auto-scroll view to keep cursor visible
    if menu_cursor < menu_scroll then
      menu_scroll = menu_cursor
    elseif menu_cursor >= menu_scroll + items_per_page then
      menu_scroll = menu_cursor - items_per_page + 1
    end
    
    -- Update current parameter
    current_param = menu_items[menu_cursor + 1]
  elseif n == 2 then
    -- Adjust current parameter
    if current_param then
      params:delta(current_param, d)
    end
  elseif n == 3 then
    -- Depth control (affects multiple parameters)
    depth = util.clamp(depth + d * 2, 0, 100)
    -- Depth affects reverb and tension
    params:set("reverb_mix", math.floor(depth * 0.8))
    params:set("tension", math.floor(depth * 0.6))
  end
  redraw()
end

-- Draw deep sea visualization
function redraw()
  screen.clear()
  screen.aa(1)
  
  -- Background gradient (darkness increases with depth)
  screen.level(math.floor(5 - depth / 25))
  
  -- Draw depth layers (only animate if playing)
  for i = 0, 3 do
    local y = (i * 16 + wave_offset) % 64
    screen.level(math.floor(3 - i * 0.5))
    screen.move(0, y)
    for x = 0, 128, 4 do
      local wave = math.sin((x + wave_offset * 2) / 20) * 3
      screen.line_rel(4, wave)
    end
    screen.stroke()
  end
  
  -- Draw particles (marine snow) - only move when playing
  for _, p in ipairs(particles) do
    if playing then
      p.y = (p.y + p.speed) % 64
    end
    screen.level(p.brightness)
    screen.circle(p.x, p.y, p.size)
    screen.fill()
  end
  
  -- Draw bioluminescent pulses - only when triggered by notes
  for _, bio in ipairs(bioluminescence) do
    if bio.active and playing then
      bio.phase = bio.phase + bio.speed
      
      -- Deactivate after one complete cycle
      if bio.phase >= 1 then
        bio.active = false
        bio.phase = 0
      end
    end
    
    -- Only draw if active
    if bio.active then
      bio.radius = math.sin(bio.phase * math.pi * 2) * bio.max_radius
      
      if bio.radius > 0 then
        screen.level(math.floor(bio.radius / bio.max_radius * 10))
        screen.circle(bio.x, bio.y, bio.radius)
        screen.stroke()
      end
    end
  end
  
  -- Draw mysterious creature silhouette - only move when playing
  if playing then
    creature_timer = creature_timer + 0.02 -- Much slower (was 0.1)
    creature_x = 64 + math.sin(creature_timer * 0.3) * 30
    
    screen.level(2)
    -- Body
    screen.circle(creature_x, 32 + visual_depth / 3, 8)
    screen.fill()
    -- Tentacles
    for i = 1, 5 do
      local angle = (i / 5) * math.pi + creature_timer * 0.2
      local tx = creature_x + math.cos(angle) * 12
      local ty = 32 + visual_depth / 3 + math.sin(angle) * 12
      screen.move(creature_x, 32 + visual_depth / 3)
      screen.line(tx, ty)
      screen.stroke()
    end
  end
  
  -- Status bar
  screen.level(15)
  screen.rect(0, 0, 128, 8)
  screen.fill()
  
  screen.level(0)
  screen.move(2, 6)
  local status_text = playing and "● DESCENDING" or "○ SURFACE"
  screen.text(status_text)
  
  -- Depth meter
  screen.level(0)
  screen.move(75, 6)  -- Moved left from 90 to give more room
  screen.text("Depth: " .. math.floor(depth) .. "m")
  
  -- Draw menu system
  if show_menu then
    -- Semi-transparent menu background
    screen.level(0)
    screen.rect(0, 10, 128, 54)
    screen.fill()
    
    screen.level(2)
    screen.rect(1, 11, 126, 52)
    screen.stroke()
    
    -- Draw menu items
    local y = 14
    for i = 1, math.min(items_per_page, #menu_items - menu_scroll) do
      local menu_index = menu_scroll + i - 1  -- 0-based index into menu_items
      local item_index = menu_items[menu_index + 1]
      local param_name = params:get_name(item_index)
      local param_val = params:string(item_index)
      
      -- Custom formatting for root_note to show note name
      if params:lookup_param(item_index).id == "root_note" then
        param_val = MusicUtil.note_num_to_name(params:get(item_index), true)
      end
      
      -- Highlight current selection based on cursor position
      if menu_index == menu_cursor then
        screen.level(15)
        screen.rect(2, y - 1, 124, 9)
        screen.fill()
        screen.level(0)
      else
        screen.level(10)
      end
      
      -- Draw parameter name and value
      screen.move(4, y + 6)
      screen.text(param_name)
      
      screen.move(124, y + 6)
      screen.text_right(param_val)
      
      y = y + 10
    end
    
    -- Scroll indicators
    if menu_scroll > 0 then
      screen.level(10)
      screen.move(64, 13)
      screen.text_center("▲")
    end
    if menu_scroll < #menu_items - items_per_page then
      screen.level(10)
      screen.move(64, 61)
      screen.text_center("▼")
    end
  end
  
  -- Draw play indicator
  if playing then
    screen.level(10)
    for i = 1, 3 do
      local pulse = math.sin(creature_timer * 2 + i) * 2
      screen.circle(120 - i * 4, 60, 1 + pulse)
      screen.fill()
    end
  end
  
  -- Draw randomize message if active
  if randomize_timer > 0 then
    -- Semi-transparent background for message
    screen.level(0)
    screen.rect(10, 24, 108, 16)
    screen.fill()
    
    screen.level(2)
    screen.rect(11, 25, 106, 14)
    screen.stroke()
    
    -- Message text
    screen.level(15)
    screen.move(64, 34)
    screen.text_center(randomize_message)
  end
  
  -- Only advance wave animation when playing
  if playing then
    wave_offset = wave_offset + 0.1 -- Much slower (was 0.5)
  end
  
  screen.update()
end

-- Draw on Grid
function grid_redraw()
  if g == nil then return end
  
  g:all(0)  -- Clear grid
  
  -- Grid dimensions (works for 64, 128, 256 grids)
  local grid_w = g.cols
  local grid_h = g.rows
  
  -- Map particles to grid (marine snow)
  for _, p in ipairs(particles) do
    local gx = math.floor(util.linlin(0, 128, 1, grid_w, p.x))
    local gy = math.floor(util.linlin(0, 64, 1, grid_h, p.y))
    
    if gx >= 1 and gx <= grid_w and gy >= 1 and gy <= grid_h then
      g:led(gx, gy, math.floor(p.brightness))
    end
  end
  
  -- Map bioluminescent pulses to grid
  for _, bio in ipairs(bioluminescence) do
    if bio.active then
      local gx = math.floor(util.linlin(0, 128, 1, grid_w, bio.x))
      local gy = math.floor(util.linlin(0, 64, 1, grid_h, bio.y))
      
      -- Draw expanding circle on grid
      local grid_radius = math.floor(util.linlin(0, 20, 0, 3, bio.radius))
      local brightness = math.floor(bio.radius / bio.max_radius * 15)
      
      for dx = -grid_radius, grid_radius do
        for dy = -grid_radius, grid_radius do
          local dist = math.sqrt(dx*dx + dy*dy)
          if dist <= grid_radius then
            local tx = gx + dx
            local ty = gy + dy
            if tx >= 1 and tx <= grid_w and ty >= 1 and ty <= grid_h then
              g:led(tx, ty, brightness)
            end
          end
        end
      end
    end
  end
  
  -- Map creature to grid
  if playing then
    local creature_gx = math.floor(util.linlin(0, 128, 1, grid_w, creature_x))
    local creature_gy = math.floor(util.linlin(0, 64, 1, grid_h, 32 + visual_depth / 3))
    
    if creature_gx >= 1 and creature_gx <= grid_w and creature_gy >= 1 and creature_gy <= grid_h then
      g:led(creature_gx, creature_gy, 4)
      -- Draw tentacles as adjacent dim LEDs
      if creature_gx > 1 then g:led(creature_gx - 1, creature_gy, 2) end
      if creature_gx < grid_w then g:led(creature_gx + 1, creature_gy, 2) end
    end
  end
  
  g:refresh()
end

-- Grid key handler
g.key = function(x, y, z)
  if z == 1 then  -- Key pressed
    -- Bottom left corner = Play/Stop (like KEY2)
    if x == 1 and y == g.rows then
      playing = not playing
      if playing then
        print("Fathom: Descending... (Grid)")
      else
        print("Fathom: Surfacing... (Grid)")
        engine.allNotesOff()
        if midi_device then
          for i = 0, 127 do
            midi_device:note_off(i, 0, midi_channel)
          end
        end
      end
      redraw()
    end
    
    -- Bottom right corner = Randomize (like KEY3 tap)
    if x == g.cols and y == g.rows then
      randomize_params()
      local menu_was_hidden = not show_menu
      show_menu = true
      redraw()
      if menu_was_hidden then
        clock.run(function()
          clock.sleep(3)
          show_menu = false
          redraw()
        end)
      end
    end
  end
end

-- Arc delta handler (encoder movement)
a.delta = function(n, d)
  if n == 1 then
    -- Encoder 1: Root Note
    local current = params:get("root_note")
    params:set("root_note", util.clamp(current + d, 24, 72))
  elseif n == 2 then
    -- Encoder 2: Density
    local current = params:get("density")
    params:delta("density", d * 0.1)
  elseif n == 3 then
    -- Encoder 3: Reverb Mix
    params:delta("reverb_mix", d)
  elseif n == 4 then
    -- Encoder 4: Filter Cutoff
    local current = params:get("filter_freq")
    local new_val = util.clamp(current + (d * 50), 100, 8000)
    params:set("filter_freq", new_val)
  end
  arc_dirty = true
  redraw()
end

-- Draw on Arc
function arc_redraw()
  if a == nil or a.device == nil then return end
  
  a:all(0)  -- Clear all LED rings
  
  -- Encoder 1: Root Note (24-72, 49 notes)
  local root_note = params:get("root_note")
  local root_pos = util.linlin(24, 72, 0, 64, root_note)
  for i = 1, math.floor(root_pos) do
    a:led(1, i, 15)
  end
  -- Dim LEDs for rest of range
  for i = math.floor(root_pos) + 1, 64 do
    a:led(1, i, 2)
  end
  
  -- Encoder 2: Density (0.5-16 beats)
  local density = params:get("density")
  local density_pos = util.linlin(0.5, 16, 0, 64, density)
  for i = 1, math.floor(density_pos) do
    a:led(2, i, 15)
  end
  for i = math.floor(density_pos) + 1, 64 do
    a:led(2, i, 2)
  end
  
  -- Encoder 3: Reverb Mix (0-100%)
  local reverb = params:get("reverb_mix")
  local reverb_pos = util.linlin(0, 100, 0, 64, reverb)
  for i = 1, math.floor(reverb_pos) do
    a:led(3, i, 15)
  end
  for i = math.floor(reverb_pos) + 1, 64 do
    a:led(3, i, 2)
  end
  
  -- Encoder 4: Filter Cutoff (100-8000 Hz, logarithmic)
  -- Only if Arc 4 is connected
  if a.device and a.device.ports and a.device.ports >= 4 then
    local filter = params:get("filter_freq")
    local filter_pos = util.linlin(100, 8000, 0, 64, filter)
    for i = 1, math.floor(filter_pos) do
      a:led(4, i, 15)
    end
    for i = math.floor(filter_pos) + 1, 64 do
      a:led(4, i, 2)
    end
  end
  
  a:refresh()
end

-- Cleanup
function cleanup()
  clock.cancel(clock_id)
  engine.allNotesOff()
  if midi_device then
    for i = 0, 127 do
      midi_device:note_off(i, 0, midi_channel)
    end
  end
end
