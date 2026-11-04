# Open-source evaluation and reuse

Evaluated https://github.com/gundy/tiny-synth (develop): SID-like voice/ADSR, TinyFPGA/PDM, CERN OHL 1.2. Not copied into this build.

Selected https://github.com/nishadsuresh/fpga-verilog-synth (main): MIT, Copyright (c) 2026 Nishad Suresh. `src/mixer.v` is copied unmodified from `rtl/mixer.v`; SHA256: `1f4cc82c0d871da5b225bd7248fddfaab8f3a3992fbf0c0c5e290c8d6679a123`. `src/mixer_pipe.v` is a pipelined adaptation. License preserved at `third_party/fpga-verilog-synth/LICENSE`. No claim is made that the upstream project is a complete board-compatible solution. Its MIDI top is monophonic and its ADSR includes dynamic divisions, so board wrapper, allocator, portable waveform generator and step envelope were implemented specifically for this project.

Accessed 2026-10-28 using connected GitHub fetch after local git network connection failed. The original mixer source is preserved with its comments. All board-specific code and constraints are newly authored with AI assistance. Competition submission must describe reuse accurately.
