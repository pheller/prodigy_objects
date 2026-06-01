# Page Template Object example
#
# A PTO is the entry point to a screen. Segments must appear in this order:
#   1. Page Format Call (required, must be first)
#   2. Page Element Calls (at least one; one per partition)
#   3. Program Call(s)   (optional; page-level initializer, post-processor, or help)
#   4. Keyword/Navigation (optional)
#
# Run with: mix run examples/page_template_object_example.exs

import ProdigyObjectDSL

pto = page_template_object "SSGC0001", "PG1" do
  # Page Format Call — must come first; references the PFO for this page.
  # The PFO (SSGC0001.FMT) defines the three partitions.
  page_format_call(:pc_prefix_program_call, "SSGC0001", "FMT")

  # Page Element Calls — one per partition defined in the PFO.
  # Each PEO supplies the presentation data for its partition.
  page_element_call(1, :pc_prefix_program_call, "SSGC0001", "HB1")  # header
  page_element_call(2, :pc_prefix_program_call, "SSGC0001", "BB1")  # body
  page_element_call(3, :pc_prefix_program_call, "SSGC0001", "AB1")  # ad

  # Page-level initializer: called before the page is displayed.
  # Loads GEVs, checks session state, etc.
  program_call(:pc_event_initializer, :pc_prefix_program_call, "SSGCA001", "PGM", <<>>, [])

  # Navigation: associates a BFD address and keyword with this page so users
  # can navigate back to it by keyword and the GUIDE feature can locate it.
  keyword_navigation("100000001.BFD  ", "GETFIT")
end

encoded = ObjectEncoder.encode(pto)

IO.puts("Object:   #{pto.object_name}.#{String.trim(pto.object_ext)}")
IO.puts("Type:     #{pto.object_type}")
IO.puts("Segments: #{length(pto.object_list)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")
IO.puts("Segment types:")
Enum.each(pto.object_list, fn seg -> IO.puts("  #{seg.__struct__}") end)
