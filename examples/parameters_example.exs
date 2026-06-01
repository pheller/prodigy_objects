# Parameters example
#
# Parameters are passed to TBOL programs from Program Call and Field Level
# Program Call segments. They are encoded as a length-prefixed list of
# length-prefixed binaries (up to 8 params). An empty binary <<>> encodes
# as a null placeholder so positional slots are preserved — e.g. if a
# program expects params 1 and 3 but not 2, pass [p1, <<>>, p3].
#
# Run with: mix run examples/parameters_example.exs

import ProdigyObjectDSL

# A search-results PEO.
#
# The page initializer receives two parameters:
#   param 1 — product category code (4-byte ASCII)
#   param 2 — maximum results to display (1-byte count)
#
# Each input field has a validator that receives three parameters:
#   param 1 — minimum input length allowed (1 byte)
#   param 2 — null placeholder (this slot unused by the validator)
#   param 3 — character class flag: 0x01 = alpha only, 0x02 = numeric only

category_code  = <<"COND">>          # conditioning equipment
max_results    = <<0x0A>>            # show up to 10 results

min_length     = <<0x01>>            # at least 1 character required
null_param     = <<>>                # positional placeholder — slot 2 unused
alpha_only     = <<0x01>>            # flag: alphabetic input only

peo = page_element_object "SSGC0005", "BB1" do
  presentation_data(:presentation_data_ascii,
    "SEARCH CONDITIONING EQUIPMENT\r\n" <>
    "\r\n" <>
    "Enter keyword: \r\n"
  )

  # Page-level initializer: loads the product catalogue for this category.
  # Params tell it which category to load and how many results to prepare.
  program_call(:pc_event_initializer, :pc_prefix_program_call,
    "SSGCA010", "PGM", <<>>,
    [category_code, max_results])

  # Single keyword input field
  field_definition(:field_state_input_field, :field_format_alphanumeric,
    {110, 100}, {100, 12}, 1, 0, 0, {110, 100})

  # Field-level post-processor validates the keyword before submitting.
  # Slot 2 is intentionally empty (the validator ignores it); slot 3 carries
  # the alpha-only flag.
  field_level_program_call(:pc_event_post_processor, 1, :pc_prefix_program_call,
    "SSGCA011", "PGM", <<>>,
    [min_length, null_param, alpha_only])
end

encoded = ObjectEncoder.encode(peo)

IO.puts("Object:   #{peo.object_name}.#{String.trim(peo.object_ext)}")
IO.puts("Encoded:  #{byte_size(encoded)} bytes")
IO.puts("")

# Show the parameter buffers as they will appear in the encoded object
pc   = Enum.find(peo.object_list, &match?(%ProgramCall{}, &1))
flpc = Enum.find(peo.object_list, &match?(%FieldLevelProgramCall{}, &1))

IO.puts("ProgramCall params:          #{inspect(pc.parameters)}")
IO.puts("FieldLevelProgramCall params: #{inspect(flpc.parameters)}")
