defmodule HeaderTest do
  use ExUnit.Case

  # Header layout (18 static bytes):
  #   0- 7  object_name (8 bytes)
  #   8-10  object_ext  (3 bytes, space-padded)
  #     11  sequence    (1 byte)
  #     12  object_type (1 byte)
  #  13-14  length      (2 bytes, little-endian, inclusive)
  #     15  candidacy_version_high
  #     16  num_objects
  #     17  candidacy_version_low

  describe "new/4" do
    test "stores name, ext, type, and object list" do
      h = Header.new("SSGC0001", "FMT", :page_format_object, [])
      assert h.object_name == "SSGC0001"
      assert h.object_ext == "FMT"
      assert h.object_type == :page_format_object
      assert h.object_list == []
    end

    test "num_objects matches object list length" do
      pd = PresentationData.new(:presentation_data_ascii, "x")
      h = Header.new("SSGC0001", "BB1", :page_element_object, [pd, pd, pd])
      assert h.num_objects == 3
    end

    test "sequence defaults to 1" do
      h = Header.new("SSGC0001", "FMT", :page_format_object, [])
      assert h.sequence == 1
    end
  end

  describe "encode/1 structure" do
    test "name occupies first 8 bytes" do
      h = Header.new("SSGC0001", "FMT", :page_format_object, [])
      <<name::binary-8, _::binary>> = ObjectEncoder.encode(h)
      assert name == "SSGC0001"
    end

    test "ext is space-padded to 3 bytes" do
      h = Header.new("SSGC0001", "PG", :page_template_object, [])
      <<_::binary-8, ext::binary-3, _::binary>> = ObjectEncoder.encode(h)
      assert ext == "PG "
    end

    test "length field is inclusive of the full encoded binary" do
      h = Header.new("SSGC0001", "FMT", :page_format_object, [])
      encoded = ObjectEncoder.encode(h)
      <<_::binary-13, length::16-little, _::binary>> = encoded
      assert length == byte_size(encoded)
    end

    test "length grows with added segments" do
      h0 = Header.new("SSGC0001", "FMT", :page_format_object, [])
      pd = PresentationData.new(:presentation_data_ascii, "hello")
      h1 = Header.new("SSGC0001", "BB1", :page_element_object, [pd])
      assert byte_size(ObjectEncoder.encode(h1)) >
               byte_size(ObjectEncoder.encode(h0))
    end
  end

  describe "encode/1 object type byte" do
    test "page_format_object encodes as 0x00" do
      h = Header.new("SSGC0001", "FMT", :page_format_object, [])
      <<_::binary-12, type_byte, _::binary>> = ObjectEncoder.encode(h)
      assert type_byte == 0x00
    end

    test "page_template_object encodes as 0x04" do
      h = Header.new("SSGC0001", "PG1", :page_template_object, [])
      <<_::binary-12, type_byte, _::binary>> = ObjectEncoder.encode(h)
      assert type_byte == 0x04
    end

    test "page_element_object encodes as 0x08" do
      h = Header.new("SSGC0001", "BB1", :page_element_object, [])
      <<_::binary-12, type_byte, _::binary>> = ObjectEncoder.encode(h)
      assert type_byte == 0x08
    end

    test "program_object encodes as 0x0C" do
      h = Header.new("SSGCA001", "PGM", :program_object, [])
      <<_::binary-12, type_byte, _::binary>> = ObjectEncoder.encode(h)
      assert type_byte == 0x0C
    end

    test "window_object encodes as 0x0E" do
      h = Header.new("SSGC0001", "WN1", :window_object, [])
      <<_::binary-12, type_byte, _::binary>> = ObjectEncoder.encode(h)
      assert type_byte == 0x0E
    end
  end
end
