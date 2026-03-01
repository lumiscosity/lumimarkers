# .lmp file format

.lmp files always start with "LMP", followed by a contiguous array of ID (u8, 1 byte), length (u16, 2 bytes) and contents (length bytes). The IDs are as follows (non-italics are corresponding to arguments to pings.lm_reconstructMarker):

- 00: name
- 01: c
- 02: spc
- 03: pos
- 04: scale
- 05: height
- 06: rot
- 07: light
- 08: dis_type
- 09: dis_cont
- 0A: *action wheel mode icon*
