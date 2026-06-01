# Page Format Object example
#
# A PFO defines the screen partitions for a page. It is the only object that
# contains Partition Definition segments. Every page needs exactly one PFO,
# called by the first segment of the Page Template Object.
#
# Screen is 240 x 200 pels. Coordinates are measured from the lower-left corner.
# ORIGIN is the lower-left corner of the partition.
# SIZE is the upper-right corner relative to ORIGIN (i.e. the width and height).
#
# Standard partition IDs:
#   1, 2, 5, 6, ... = Header, Body, and Window partitions
#   3               = Ad partition
#   4               = Command Bar (displayed automatically, not defined in PFO)
#
# Run with: mix run examples/page_format_object_example.exs

import ProdigyObjectDSL

# "Get Fit" conditioning equipment page layout:
#   Partition 1 (header): top 40 pels   — y 160..200
#   Partition 2 (body):   middle 120 pels — y 40..160
#   Partition 3 (ad):     bottom 40 pels — y 0..40
#   (Command bar at very bottom is shown automatically)

pfo = page_format_object "SSGC0001", "FMT" do
  partition_definition(1, {0, 160}, {240, 40})   # header
  partition_definition(2, {0, 40},  {240, 120})  # body
  partition_definition(3, {0, 0},   {240, 40})   # ad
end

encoded = ObjectEncoder.encode(pfo)

IO.puts("Object:   #{pfo.object_name}.#{String.trim(pfo.object_ext)}")
IO.puts("Type:     #{pfo.object_type}")
IO.puts("Segments: #{length(pfo.object_list)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")
IO.puts("Partition IDs: #{Enum.map(pfo.object_list, & &1.partition_id) |> inspect()}")
