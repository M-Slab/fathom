// Engine_Fathom
// Dark ambient synthesis engine for Norns
// Combines FM synthesis, granular textures, and spatial effects

Engine_Fathom : CroneEngine {
    var synths;
    var reverbBus, delayBus;
    var reverbSynth, delaySynth;
    var masterGroup, synthGroup, fxGroup;
    
    *new { arg context, doneCallback;
        ^super.new(context, doneCallback);
    }
    
    alloc {
        // Initialize groups
        masterGroup = Group.new(context.xg);
        synthGroup = Group.head(masterGroup);
        fxGroup = Group.tail(masterGroup);
        
        // Audio buses for effects
        reverbBus = Bus.audio(context.server, 2);
        delayBus = Bus.audio(context.server, 2);
        
        synths = Dictionary.new;
        
        // Define SynthDefs
        this.addSynthDefs;
        
        context.server.sync;
        
        // Start effects chains
        this.startEffects;
        
        // Add commands
        this.addCommands;
    }
    
    addSynthDefs {
        // Main dark ambient voice - FM synthesis with noise
        SynthDef(\fathomVoice, {
            arg out, freq = 220, amp = 0.3, gate = 1,
                modIndex = 2, modRatio = 1.5,
                filterFreq = 2000, filterRes = 0.2,
                attackTime = 0.8, releaseTime = 3.0,
                reverbSend = 0.6, delaySend = 0.3;
            
            var sig, env, mod, carrier, noise, filtered;
            
            // Envelope
            env = EnvGen.kr(
                Env.asr(attackTime, 1, releaseTime, curve: -4),
                gate,
                doneAction: 2
            );
            
            // FM synthesis for tonal component
            mod = SinOsc.ar(freq * modRatio) * freq * modIndex * env;
            carrier = SinOsc.ar(freq + mod);
            
            // Add sub harmonic
            carrier = carrier + SinOsc.ar(freq * 0.5, mul: 0.3);
            
            // Noise component for texture
            noise = PinkNoise.ar(0.1) * LFNoise1.kr(0.5).range(0.5, 1);
            
            // Combine
            sig = (carrier * 0.7) + (noise * 0.3);
            
            // Filter
            sig = MoogFF.ar(sig, filterFreq, filterRes);
            
            // Apply envelope and amplitude
            sig = sig * env * amp;
            
            // Stereo spread
            sig = sig * [1, 1.01];
            
            // Send to effects
            Out.ar(out, sig);
            Out.ar(\reverbBus.kr, sig * reverbSend);
            Out.ar(\delayBus.kr, sig * delaySend);
        }).add;
        
        // Textural drone layer
        SynthDef(\fathomTexture, {
            arg out, freq = 100, amp = 0.2, dur = 8,
                reverbSend = 0.8, delaySend = 0.4;
            
            var sig, env, grain1, grain2, grain3;
            
            env = EnvGen.kr(
                Env.linen(dur * 0.3, dur * 0.4, dur * 0.3),
                doneAction: 2
            );
            
            // Multiple grain sources
            grain1 = SinOsc.ar(freq * [1, 1.01], mul: 0.3);
            grain2 = SinOsc.ar(freq * [0.5, 0.501], mul: 0.2);
            grain3 = LFTri.ar(freq * [1.5, 1.503], mul: 0.15);
            
            sig = grain1 + grain2 + grain3;
            
            // Slow filter modulation
            sig = LPF.ar(sig, 
                LFNoise1.kr(0.1).range(200, 1500)
            );
            
            // Add resonance
            sig = Resonz.ar(sig, freq * 2, 0.01, mul: 2) + sig;
            
            sig = sig * env * amp;
            
            // Send to effects
            Out.ar(out, sig);
            Out.ar(\reverbBus.kr, sig * reverbSend);
            Out.ar(\delayBus.kr, sig * delaySend);
        }).add;
        
        // Reverb effect
        SynthDef(\fathomReverb, {
            arg in, out, mix = 0.6, room = 0.8, damp = 0.4;
            
            var sig, wet;
            
            sig = In.ar(in, 2);
            
            wet = FreeVerb2.ar(
                sig[0], sig[1],
                mix: 1.0,
                room: room,
                damp: damp
            );
            
            Out.ar(out, wet * mix + (sig * (1 - mix)));
        }).add;
        
        // Delay effect
        SynthDef(\fathomDelay, {
            arg in, out, time = 0.5, feedback = 0.5, mix = 0.3;
            
            var sig, delayed;
            
            sig = In.ar(in, 2);
            
            delayed = sig + LocalIn.ar(2);
            delayed = DelayC.ar(delayed, 2.0, time);
            delayed = LPF.ar(delayed, 6000); // Dark delay
            LocalOut.ar(delayed * feedback);
            
            Out.ar(out, (delayed * mix) + (sig * (1 - mix)));
        }).add;
    }
    
    startEffects {
        // Start reverb
        reverbSynth = Synth(\fathomReverb, [
            \in, reverbBus,
            \out, context.out_b,
            \mix, 0.6,
            \room, 0.8,
            \damp, 0.4
        ], fxGroup);
        
        // Start delay
        delaySynth = Synth(\fathomDelay, [
            \in, delayBus,
            \out, context.out_b,
            \time, 0.5,
            \feedback, 0.5,
            \mix, 0.3
        ], fxGroup);
    }
    
    addCommands {
        // Note on command
        this.addCommand(\noteOn, "if", { arg msg;
            var note = msg[1].asInteger;
            var velocity = msg[2].asFloat;
            
            var freq = note.midicps;
            var amp = velocity * 0.6;
            
            // Stop existing note if playing
            if (synths[note].notNil, {
                synths[note].set(\gate, 0);
            });
            
            // Create new synth
            synths[note] = Synth(\fathomVoice, [
                \out, context.out_b,
                \freq, freq,
                \amp, amp,
                \reverbBus, reverbBus,
                \delayBus, delayBus,
                \modIndex, rrand(1.5, 3.5),
                \modRatio, [1.5, 2.0, 3.0, 4.0].choose,
                \filterFreq, rrand(800, 3000),
                \attackTime, rrand(0.5, 1.5),
                \releaseTime, rrand(2.0, 5.0)
            ], synthGroup);
        });
        
        // Note off command
        this.addCommand(\noteOff, "i", { arg msg;
            var note = msg[1].asInteger;
            
            if (synths[note].notNil, {
                synths[note].set(\gate, 0);
                synths[note] = nil;
            });
        });
        
        // All notes off
        this.addCommand(\allNotesOff, "", {
            synths.do({ arg synth;
                if (synth.notNil, {
                    synth.set(\gate, 0);
                });
            });
            synths.clear;
        });
        
        // Texture layer
        this.addCommand(\texture, "f", { arg msg;
            var baseFreq = msg[1].asFloat.midicps;
            
            Synth(\fathomTexture, [
                \out, context.out_b,
                \freq, baseFreq,
                \amp, rrand(0.1, 0.3),
                \dur, rrand(6, 12),
                \reverbBus, reverbBus,
                \delayBus, delayBus
            ], synthGroup);
        });
        
        // Global amplitude
        this.addCommand(\amp, "f", { arg msg;
            synthGroup.set(\amp, msg[1]);
        });
        
        // Reverb controls
        this.addCommand(\reverbMix, "f", { arg msg;
            reverbSynth.set(\mix, msg[1]);
        });
        
        this.addCommand(\reverbSize, "f", { arg msg;
            reverbSynth.set(\room, msg[1]);
        });
        
        this.addCommand(\reverbDamp, "f", { arg msg;
            reverbSynth.set(\damp, msg[1]);
        });
        
        // Delay controls
        this.addCommand(\delayTime, "f", { arg msg;
            delaySynth.set(\time, msg[1]);
        });
        
        this.addCommand(\delayFeedback, "f", { arg msg;
            delaySynth.set(\feedback, msg[1]);
        });
        
        this.addCommand(\delayMix, "f", { arg msg;
            delaySynth.set(\mix, msg[1]);
        });
        
        // Filter controls
        this.addCommand(\filterFreq, "f", { arg msg;
            synthGroup.set(\filterFreq, msg[1]);
        });
        
        this.addCommand(\filterRes, "f", { arg msg;
            synthGroup.set(\filterRes, msg[1]);
        });
    }
    
    free {
        synths.do({ arg synth;
            synth.free;
        });
        reverbSynth.free;
        delaySynth.free;
        reverbBus.free;
        delayBus.free;
        masterGroup.free;
    }
}
