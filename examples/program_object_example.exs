# Program Object example
#
# A PDO (Program/Data Object) contains either:
#   :program_data_tbol        — compiled TBOL bytecode (use the ~TBOL sigil, see
#                               tbol_example.exs, when tbolc is available)
#   :program_data_application — arbitrary binary data read by TBOL programs at runtime
#
# This example builds a PDO carrying a navigation dispatch table as application data.
# A separate TBOL program would read the table at runtime and navigate accordingly.
#
# Run with: mix run examples/program_object_example.exs

import ProdigyObjectDSL

# Navigation dispatch table.
# Each 16-byte entry maps a menu-choice number to the 11-byte object name + 1-byte type
# of the destination page, followed by a 3-byte control field.
# Entry format: <<choice, name::binary-8, ext::binary-3, seq, type>>
# 0xFF terminates the table.

treadmills  = <<1, "SSGC0002", "PG1", 0x00, 0x04>>
bikes       = <<2, "SSGC0003", "PG1", 0x00, 0x04>>
weights     = <<3, "SSGC0004", "PG1", 0x00, 0x04>>
end_marker  = <<0xFF>>

nav_table = treadmills <> bikes <> weights <> end_marker

pdo = program_object "SSGCA001", "PGM" do
  program_data(:program_data_application, nav_table)
end

encoded = ObjectEncoder.encode(pdo)

IO.puts("Object:      #{pdo.object_name}.#{String.trim(pdo.object_ext)}")
IO.puts("Type:        #{pdo.object_type}")
IO.puts("Segments:    #{length(pdo.object_list)}")
IO.puts("Encoded:     #{byte_size(encoded)} bytes")
IO.puts("")
IO.puts("Table entries: #{div(byte_size(nav_table) - 1, 14)}")
IO.puts("(Use ~TBOL in tbol_example.exs to build a PDO from TBOL source instead)")
