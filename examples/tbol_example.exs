# TBOL sigil example
#
# The ~TBOL sigil compiles TBOL source code at build time:
#   1. Writes the source to a temporary .src file
#   2. Runs `tbolc <file.src>` — tbolc must be on PATH
#   3. Reads the resulting .cod file
#   4. Embeds the compiled binary as a ProgramData segment
#
# The compiled bytes are baked into the Elixir BEAM file, so tbolc only
# runs during compilation, not at runtime.
#
# REQUIRES: tbolc installed and on PATH. This file will fail to compile
# without it. All other examples in this directory work without tbolc.
#
# Run with: mix run examples/tbol_example.exs

import ProdigyObjectDSL

# Post-processor for the conditioning equipment menu.
# Reads the user's menu choice from PEV(1) and navigates to the
# corresponding subcategory page.

pdo = program_object "SSGCA002", "PGM" do
  ~TBOL"""
  ; Post-processor: navigate based on user's menu choice
  LET CHOICE = PEV(1)
  IF CHOICE = 1 THEN NAVIGATE "SSGC0002.PG1"
  IF CHOICE = 2 THEN NAVIGATE "SSGC0003.PG1"
  IF CHOICE = 3 THEN NAVIGATE "SSGC0004.PG1"
  """
end

encoded = ObjectEncoder.encode(pdo)

IO.puts("Object:   #{pdo.object_name}.#{String.trim(pdo.object_ext)}")
IO.puts("Type:     #{pdo.object_type}")
IO.puts("Segments: #{length(pdo.object_list)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")
[seg] = pdo.object_list
IO.puts("Program data type: #{seg.program_data_type}")
IO.puts("Compiled size:     #{byte_size(seg.data)} bytes")
