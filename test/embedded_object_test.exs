defmodule EmbeddedObjectTest do
  use ExUnit.Case

  # Layout:
  #   0    ST    0x52
  #   1-2  SL    little-endian, inclusive
  #   3+   data  variable

  describe "new/1" do
    test "stores data" do
      eo = EmbeddedObject.new(<<0xDE, 0xAD>>)
      assert eo.segment_type == :embedded_object
      assert eo.data == <<0xDE, 0xAD>>
    end

    test "accepts empty data" do
      eo = EmbeddedObject.new(<<>>)
      assert eo.data == <<>>
    end
  end

  describe "encode/1" do
    test "ST byte is 0x52" do
      eo = EmbeddedObject.new(<<>>)
      <<st, _::binary>> = ObjectEncoder.encode(eo)
      assert st == 0x52
    end

    test "SL equals total encoded size" do
      eo = EmbeddedObject.new(<<1, 2, 3>>)
      encoded = ObjectEncoder.encode(eo)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "empty data produces 3-byte encoding" do
      eo = EmbeddedObject.new(<<>>)
      assert byte_size(ObjectEncoder.encode(eo)) == 3
    end

    test "data bytes follow the SL field" do
      data = <<0xCA, 0xFE, 0xBA, 0xBE>>
      eo = EmbeddedObject.new(data)
      <<_st, _sl::16-little, payload::binary>> = ObjectEncoder.encode(eo)
      assert payload == data
    end

    test "encoded size grows with data" do
      eo_small = EmbeddedObject.new(<<0x01>>)
      eo_large = EmbeddedObject.new(<<0x01, 0x02, 0x03, 0x04>>)
      assert byte_size(ObjectEncoder.encode(eo_large)) ==
               byte_size(ObjectEncoder.encode(eo_small)) + 3
    end
  end
end
