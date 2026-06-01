# Page Element Object example
#
# A PEO carries the display content for one partition. It must contain a
# Presentation Data segment, and may also contain field definitions, custom
# text/cursor overrides, and program calls.
#
# Field names 1-9 are reserved for menu-choice fields. The user selects a
# choice by moving to that field and pressing ENTER; the post-processor program
# reads PEV(field_name) to find out which choice was made.
#
# Run with: mix run examples/page_element_object_example.exs

import ProdigyObjectDSL

# Body PEO for the "Get Fit" conditioning equipment category page.
# Displays a menu of equipment subcategories; the post-processor navigates
# to the chosen subcategory page.

peo = page_element_object "SSGC0001", "BB1" do
  # ASCII presentation data — the static text/layout drawn into this partition.
  # In a production object this would be NAPLPS graphics commands.
  presentation_data(:presentation_data_ascii,
    "GET FIT - CONDITIONING EQUIPMENT\r\n" <>
    "\r\n" <>
    "1  Treadmills\r\n" <>
    "2  Stationary Bikes\r\n" <>
    "3  Weight Machines\r\n"
  )

  # Custom text segment: reference ID 1, white-on-black color scheme.
  # Fields that reference text_id=1 will use these colors instead of the defaults.
  custom_text(1, 0x0F, 0x00)

  # Three action fields for the menu choices.
  # ORIGIN is the lower-left corner of each field; SIZE is width x height in pels.
  # field_name 1-3 correspond to menu choices 1-3.
  # text_id=1 applies the white-on-black custom text above.
  # cursor_id=0 means use the default blinking-box cursor.
  field_definition(:field_state_action_field, :field_format_alphanumeric,
    {10, 120}, {220, 12}, 1, 1, 0, {10, 120})
  field_definition(:field_state_action_field, :field_format_alphanumeric,
    {10, 100}, {220, 12}, 2, 1, 0, {10, 100})
  field_definition(:field_state_action_field, :field_format_alphanumeric,
    {10, 80},  {220, 12}, 3, 1, 0, {10, 80})

  # Post-processor: called after the user commits a choice.
  # Reads PEV(1..3) and navigates to the appropriate page.
  program_call(:pc_event_post_processor, :pc_prefix_program_call, "SSGCA002", "PGM", <<>>, [])
end

encoded = ObjectEncoder.encode(peo)

IO.puts("Object:   #{peo.object_name}.#{String.trim(peo.object_ext)}")
IO.puts("Type:     #{peo.object_type}")
IO.puts("Segments: #{length(peo.object_list)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")
IO.puts("Fields defined: #{peo.object_list |> Enum.count(&match?(%FieldDefinition{}, &1))}")
