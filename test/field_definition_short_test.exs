defmodule FieldDefinitionShortTest do
  use ExUnit.Case

  # The first field definition of a traced HEADLINE NEWS body, with framing.
  @recovered Base.decode16!("040D008000C1C6EAC0C9E30101")

  test "new/6 reproduces the cursor-less form byte for byte" do
    fd =
      FieldDefinition.new(
        :field_state_action_field,
        :field_format_alphanumeric,
        {5, 114},
        {12, 11},
        1,
        1
      )

    assert ObjectEncoder.encode(fd) == @recovered
  end

  test "naming a cursor adds four bytes" do
    with_cursor =
      FieldDefinition.new(
        :field_state_action_field,
        :field_format_alphanumeric,
        {5, 114},
        {12, 11},
        1,
        1,
        0,
        {0, 0}
      )

    assert byte_size(ObjectEncoder.encode(with_cursor)) == byte_size(@recovered) + 4
  end
end
