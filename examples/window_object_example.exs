# Window Element Object example
#
# A WEO defines a popup window that overlays part of the base page. Unlike a PEO,
# a WEO must include its own Partition Definition segment declaring the window's
# position and size. It can contain presentation data and fields directly, or
# delegate to a PEO via a Page Element Call.
#
# Windows can be opened from the Command Bar (JUMP, HELP) or by an application
# (e.g. by committing on an input field). Closing a window returns to the base
# page, navigates away, or opens another window.
#
# Run with: mix run examples/window_object_example.exs

import ProdigyObjectDSL

# A purchase-confirmation dialog.
# Centered on the 240x200 screen: 160 pels wide, 80 pels tall.
# ORIGIN (40, 60) → upper-right at (200, 140), leaving a visible border
# around the base page content on all sides.

weo = window_object "SSGC0001", "WN1" do
  # Required: defines where the window sits on the screen.
  # Partition ID 6 is a window partition (IDs 6+ are used for windows).
  partition_definition(6, {40, 60}, {160, 80})

  # Display content for the window.
  presentation_data(:presentation_data_ascii,
    "ADD TO CART?\r\n" <>
    "\r\n" <>
    "1  Yes, add this item\r\n" <>
    "2  No, go back\r\n"
  )

  # Single action field for the yes/no choice.
  field_definition(:field_state_action_field, :field_format_alphanumeric,
    {50, 70}, {60, 12}, 1, 0, 0, {50, 70})

  # Post-processor handles the choice: adds to cart or closes the window.
  program_call(:pc_event_post_processor, :pc_prefix_program_call, "SSGCA003", "PGM", <<>>, [])
end

encoded = ObjectEncoder.encode(weo)

IO.puts("Object:   #{weo.object_name}.#{String.trim(weo.object_ext)}")
IO.puts("Type:     #{weo.object_type}")
IO.puts("Segments: #{length(weo.object_list)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")
partition = Enum.find(weo.object_list, &match?(%PartitionDefinition{}, &1))
IO.puts("Window partition: ID=#{partition.partition_id}, " <>
  "origin=#{inspect(partition.origin)}, size=#{inspect(partition.size)}")
