defmodule FieldDefinitionTest do
  use ExUnit.Case

  # Encoded layout (17 bytes total):
  #   0    ST           0x04
  #   1-2  SL           17 (little-endian)
  #   3    field_state  1 byte
  #   4    field_format 1 byte
  #   5-7  origin       3 bytes (NAPLPS)
  #   8-10 size         3 bytes (NAPLPS)
  #   11   field_name   1 byte
  #   12   text_id      1 byte
  #   13   cursor_id    1 byte
  #  14-16 cursor_origin 3 bytes (NAPLPS)

  @origin {10, 30}
  @size   {60, 12}
  @cursor_origin {10, 30}

  def sample do
    FieldDefinition.new(
      :field_state_input_field,
      :field_format_alphanumeric,
      @origin, @size, 1, 0, 0, @cursor_origin
    )
  end

  describe "new/8" do
    test "stores all fields" do
      fd = sample()
      assert fd.segment_type == :field_definition
      assert fd.field_state == :field_state_input_field
      assert fd.field_format == :field_format_alphanumeric
      assert fd.origin == @origin
      assert fd.size == @size
      assert fd.field_name == 1
      assert fd.text_id == 0
      assert fd.cursor_id == 0
      assert fd.cursor_origin == @cursor_origin
    end

    test "segment_length is 17" do
      assert sample().segment_length == 17
    end
  end

  describe "encode/1" do
    test "ST byte is 0x04" do
      <<st, _::binary>> = ObjectEncoder.encode(sample())
      assert st == 0x04
    end

    test "total encoded size is 17 bytes" do
      assert byte_size(ObjectEncoder.encode(sample())) == 17
    end

    test "SL matches total encoded size" do
      encoded = ObjectEncoder.encode(sample())
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "field_state_input_field encodes as 0x20" do
      <<_st, _sl::16-little, state, _::binary>> = ObjectEncoder.encode(sample())
      assert state == 0x20
    end

    test "field_state_display_only encodes as 0x40" do
      fd = FieldDefinition.new(:field_state_display_only, :field_format_alphanumeric,
                               @origin, @size, 1, 0, 0, @cursor_origin)
      <<_st, _sl::16-little, state, _::binary>> = ObjectEncoder.encode(fd)
      assert state == 0x40
    end

    test "field_state_action_field encodes as 0x80" do
      fd = FieldDefinition.new(:field_state_action_field, :field_format_alphanumeric,
                               @origin, @size, 1, 0, 0, @cursor_origin)
      <<_st, _sl::16-little, state, _::binary>> = ObjectEncoder.encode(fd)
      assert state == 0x80
    end

    test "field_format_alphanumeric encodes as 0x00" do
      <<_st, _sl::16-little, _state, fmt, _::binary>> = ObjectEncoder.encode(sample())
      assert fmt == 0x00
    end

    test "origin encoded as NAPLPS coords" do
      <<_::binary-5, origin::binary-3, _::binary>> = ObjectEncoder.encode(sample())
      assert origin == ObjectUtils.naplps_coords(@origin)
    end

    test "size encoded as NAPLPS coords" do
      <<_::binary-8, size::binary-3, _::binary>> = ObjectEncoder.encode(sample())
      assert size == ObjectUtils.naplps_coords(@size)
    end

    test "field_name, text_id, cursor_id each one byte" do
      fd = FieldDefinition.new(:field_state_input_field, :field_format_alphanumeric,
                               @origin, @size, 3, 2, 1, @cursor_origin)
      <<_::binary-11, field_name, text_id, cursor_id, _::binary>> = ObjectEncoder.encode(fd)
      assert field_name == 3
      assert text_id == 2
      assert cursor_id == 1
    end

    test "cursor_origin encoded as NAPLPS coords" do
      <<_::binary-14, cursor_origin::binary-3>> = ObjectEncoder.encode(sample())
      assert cursor_origin == ObjectUtils.naplps_coords(@cursor_origin)
    end
  end
end
