# Fathom

**Dark Ambient Generative Music for Monome Norns**

Fathom is a generative music script that creates evolving dark ambient soundscapes inspired by the mysterious depths of the ocean abyss. It combines algorithmic composition, FM synthesis, and spatial effects to create cinematic, moody atmospheres.

## Features

### Sound Generation
- **Internal synthesis engine** using FM synthesis with filtered noise
- **Generative composition** based on scales, probability, and tension parameters
- **Textural layers** that add depth and movement
- **Built-in effects** including reverb and delay optimized for dark ambient
- **MIDI output** to control external synthesizers

### Visual Interface
- **Deep sea themed display** with animated particles (marine snow)
- **Bioluminescent pulses** that trigger when notes are played - visual feedback for each note
- **Mysterious creature** that drifts through the depths
- **Animations sync with playback** - they pause when stopped, resume when playing
- **Slow, meditative animation speeds** matching the dark ambient aesthetic
- **Scrollable menu system** showing 5 parameters at once for easy navigation
- **Depth meter** showing current parameter intensity
- **Real-time parameter display** with highlighted selection
- **Grid support** - visualization mirrors to connected Monome Grid (64/128/256)
  - Particles appear as drifting dim LEDs
  - Bioluminescent pulses expand as circles when notes trigger
  - Creature shows as a brighter LED moving through the grid
  - Bottom-left button = Play/Stop
  - Bottom-right button = Randomize
- **Arc support** - direct parameter control with LED feedback (Arc 2 or Arc 4)
  - Ring 1: Root Note
  - Ring 2: Density
  - Ring 3: Reverb Mix
  - Ring 4: Filter Cutoff

### Generative Controls
- **Randomization** creates unique soundscapes on each launch
- **Play/Stop** control with graceful note handling
- **User-adjustable parameters** for fine-tuning the generation
- **Depth control** (ENC3) that simultaneously affects multiple parameters

## Installation

1. Copy the `fathom` folder to your Norns `code` directory:
   ```
   ~/dust/code/fathom/
   ```

2. The folder should contain:
   - `fathom.lua` (main script)
   - `lib/Engine_Fathom.sc` (SuperCollider engine)

3. Restart your Norns or run `;restart` in maiden

4. Select Fathom from the SELECT menu

## Controls

### Keys
- **KEY2**: Play/Stop - Starts or stops the generative sequencer (animations pause when stopped)
- **KEY3 (short press)**: Randomize - Generates new random parameters optimized for dark ambient
  - Shows "PARAMETERS RANDOMIZED" message on screen
  - Temporarily displays menu for 3 seconds (if hidden) so you can see what changed
- **KEY3 (long press ~0.5s)**: Toggle Menu - Hide/show the parameter menu to view graphics

### Encoders
- **ENC1**: Scroll through parameters menu (when menu is visible)
- **ENC2**: Adjust the selected parameter value
- **ENC3**: Depth control (displayed in top right) - simultaneously adjusts reverb mix and tension
  - Think of it as diving deeper into the abyss
  - Higher depth = more reverb, more tension/movement
  - Range: 0-100m
  - Note: The creature's vertical position animates independently for visual effect and doesn't affect your depth setting

### Grid (Optional)
If you have a Monome Grid connected:
- **Visual Display**: The deep sea visualization appears on the Grid LEDs in real-time
  - Particles drift as dim LEDs
  - Bioluminescent pulses expand as circles when notes play
  - Creature appears as a bright LED moving through space
- **Bottom-Left Button**: Play/Stop toggle
- **Bottom-Right Button**: Randomize parameters

The Grid visualization works with any Grid size (64, 128, or 256).

### Arc (Optional)
If you have a Monome Arc connected, the encoders provide direct control over key parameters with LED feedback:
- **Ring 1**: Root Note (24-72)
- **Ring 2**: Density (0.5-16 beats)
- **Ring 3**: Reverb Mix (0-100%)
- **Ring 4**: Filter Cutoff (100-8000 Hz)

Each ring displays the current parameter value as a lit arc, with dim LEDs showing the full range. Works with Arc 2 or Arc 4 (Ring 4 only available on Arc 4).

### Menu System
The script features a traditional scrollable menu showing 5 parameters at a time. The currently selected parameter is highlighted. Use ENC1 to scroll through all available parameters, and scroll indicators (▲▼) show when more parameters are available above or below. Long press KEY3 to hide the menu and enjoy the full deep sea visualization.

The menu starts hidden by default to showcase the graphics. Long press KEY3 to bring it up when you need to adjust parameters.

## Parameters

The parameters are organized in the menu for easy navigation:

### Musical Parameters (Key, Octave, Tempo)

**Root Note** (24-72, default: 40/E2)
- The tonal center of the generated music
- Displayed as note name with octave (e.g., C3, F#2, A4)
- Lower values create darker, more ominous tones
- Default is set low for cinematic depth

**Scale** (7 options, default: Minor)
- Minor: Classic dark minor scale
- Phrygian: Spanish/Middle Eastern dark mode
- Locrian: Most unstable and dissonant mode
- Harmonic Minor: Dramatic with raised 7th
- Dorian: Minor with a brighter 6th
- Minor Pentatonic: Simple, meditative
- Whole Tone: Dreamlike, ambiguous

**Octave Range** (1-5, default: 2)
- How many octaves the generator can span
- Limited default keeps sound in lower, darker registers
- Higher values create more dramatic intervallic leaps

**Density** (0.5-16 beats, default: 6)
- Time between potential note triggers
- Lower values = more frequent notes
- Higher default creates sparse, cinematic pacing

**Tension** (0-100%, default: 35%)
- Controls melodic movement
- Low tension: notes stay close together, more repetitive
- Default kept low for slow, meditative evolution

**Probability** (0-100%, default: 65%)
- Chance that a note will actually trigger
- Lower default creates more space and silence
- Creates natural breathing room in compositions

**Note Duration** (0.1-8 sec, default: 4 sec)
- How long each note sustains
- Long default creates drone-like, evolving textures

### Effects Parameters

**Reverb Mix** (0-100%, default: 60%)
- Wet/dry balance of the reverb effect
- Higher values create more spacious, distant sounds

**Reverb Size** (0-100%, default: 80%)
- Size of the reverb space
- Higher values = larger, more cavernous spaces

**Reverb Damp** (0-100%, default: 40%)
- High-frequency damping in the reverb
- Higher values = darker, more muffled reverb

**Delay Time** (0.1-2 sec, default: 0.5 sec)
- Time between delay repeats
- Can be synced rhythmically or set for atmospheric echoes

**Delay Feedback** (0-95%, default: 50%)
- How many times the delay repeats
- Higher values create longer echo trails

**Delay Mix** (0-100%, default: 30%)
- Wet/dry balance of the delay effect

### Synth Engine Parameters

**Filter Cutoff** (100-8000 Hz, default: 2000 Hz)
- Low-pass filter frequency
- Lower values = darker, more muffled sound

**Filter Resonance** (0-100%, default: 20%)
- Filter resonance/emphasis
- Higher values emphasize the cutoff frequency

**Amplitude** (0-100%, default: 75%)
- Overall output level

### Other Parameters

**MIDI Out** (Off/On, default: Off)
- Enable MIDI output on port 1, channel 1
- Notes are sent with velocity based on internal generation
- Note-off messages sent when notes end

## Sound Design Tips

### Creating Different Moods

**Deep Abyss** (Minimal, Sparse)
- Low root note (36-42)
- Locrian or Phrygian scale
- High density (8-12 beats)
- Low probability (40-60%)
- High reverb mix (80%+)

**Restless Ocean** (Active, Evolving)
- Medium root note (48-54)
- Harmonic Minor or Dorian
- Medium density (2-4 beats)
- High probability (80-90%)
- High tension (70%+)

**Mysterious Depths** (Atmospheric, Cinematic)
- Low-medium root note (42-48)
- Minor or Minor Pentatonic
- Medium-high density (4-6 beats)
- Medium probability (60-75%)
- Long note durations (3-6 sec)
- Very high reverb size (90%+)

**Submarine Meditation** (Calm, Meditative)
- Low root note (36-40)
- Minor Pentatonic or Whole Tone
- High density (6-10 beats)
- Low tension (20-40%)
- Low probability (50-70%)

### External Synthesis Tips

When using MIDI output to control external synthesizers:

1. Choose synth patches with:
   - Slow attack/release envelopes
   - Dark, filtered timbres
   - Built-in modulation (LFOs, filter sweeps)
   - Pad or drone characteristics

2. Layer Fathom's internal sounds with external synths for depth

3. Use external effects (additional reverb, chorus, distortion) for more complex textures

4. Try routing MIDI to multiple devices for layered polysynth effects

## Technical Notes

### Synthesis Engine

The Fathom engine uses:
- **FM synthesis** for tonal components (carrier + modulator with randomized ratios)
- **Pink noise** mixed in for texture and grit
- **Moog ladder filter** for warm, analog-style filtering
- **Sub-harmonic generation** for deeper bass presence
- **FreeVerb2** for stereo reverb processing
- **Filtered delay line** with feedback control

### Generative Algorithm

The note generation system:
1. Selects notes from the chosen scale within the octave range
2. Uses tension parameter to decide between stepwise motion vs. leaps
3. Applies probability to determine if a note triggers
4. Adds occasional textural drone layers for depth
5. Randomizes synthesis parameters per note for variation

## Troubleshooting

**No sound:**
- Check that the engine loaded correctly in maiden (look for "Engine_Fathom")
- Verify audio output levels in SYSTEM > AUDIO
- Make sure amplitude parameter is above 0%
- Press KEY2 to ensure playback is active

**Crackling or distortion:**
- Lower the amplitude parameter
- Reduce reverb feedback
- Reduce delay feedback
- Lower filter resonance

**Notes not changing:**
- Increase tension parameter
- Check that octave range is > 1
- Try randomizing parameters (KEY3)

**MIDI not working:**
- Verify MIDI cable connections
- Check that MIDI Out is set to "On"
- Confirm receiving device is on MIDI channel 1
- Check SYSTEM > DEVICES > MIDI to see connected devices

## Credits

Created for the dark ambient music community.

Inspired by the mysterious depths of the ocean, where light fades and strange creatures drift in the eternal darkness.

## Version History

**v1.5** - Grid & Arc integration
- Added Monome Arc support - direct parameter control with LED feedback
  - Ring 1: Root Note, Ring 2: Density, Ring 3: Reverb Mix, Ring 4: Filter Cutoff
- Added Monome Grid support - deep sea visualization mirrors to Grid LEDs
- Grid buttons: bottom-left = play/stop, bottom-right = randomize
- Added poetic quote to header display
- Separated visual depth animation from depth parameter control (fixes jumping reverb/tension)
- Bioluminescent rings now trigger with each note for direct visual feedback
- Reorganized menu: Musical parameters (key/octave/tempo) → Effects → Synth Engine → Other
- Menu now shows only script parameters (17 items) instead of all system parameters
- Root note now displays as note name with octave (e.g., "C3")
- Added traditional scrollable menu system (5 items visible)
- Fixed menu scrolling bug - cursor now properly reaches all parameters
- Menu starts hidden by default to showcase graphics
- KEY3 short press = randomize, long press = toggle menu (avoids Norns system menu conflict)
- Visual feedback when randomizing parameters
- Depth meter moved left to prevent number cutoff
- Animations now start/stop with playback
- Significantly slowed animation speeds for meditative atmosphere
- Optimized defaults for darker, slower, more cinematic output
- Limited note range to lower octaves for deeper sound
- Longer default note durations and sparser density

**v1.0** - Initial release
- FM synthesis engine with effects
- Generative sequencer with scale-based composition
- Deep sea visual interface
- MIDI output support
- Parameter randomization

---

*"In the fathomless depths, sound becomes texture, and silence becomes presence."*
