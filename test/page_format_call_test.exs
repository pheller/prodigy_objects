defmodule PageFormatCallTest do
  use ExUnit.Case

  # External call layout (17 bytes):
  #   0    ST      0x31
  #   1-2  SL      17 (little-endian)
  #   3    prefix  0x0D
  #   4-11 name    8 bytes
  #  12-14 ext     3 bytes
  #    15  seq     0x00
  #    16  type    0x00 (page_format_object)

  # Embedded call layout (6 bytes, no embedded object):
  #   0    ST      0x31
  #   1-2  SL      6 (little-endian)
  #   3    prefix  0x0F
  #   4-5  offset  0x0000 (little-endian)

  describe "new/3" do
    test "stores prefix, name, ext" do
      pfc = PageFormatCall.new(:pc_prefix_program_call, "SSGC0001", "FMT")
      assert pfc.segment_type == :page_format_call
      assert pfc.prefix == :pc_prefix_program_call
      assert pfc.object_name == "SSGC0001"
      assert pfc.object_ext == "FMT"
    end

    test "offset defaults to 0" do
      pfc = PageFormatCall.new(:pc_prefix_program_call, "SSGC0001", "FMT")
      assert pfc.offset == 0
    end
  end

  describe "encode/1 — external call" do
    setup do
      pfc = PageFormatCall.new(:pc_prefix_program_call, "SSGC0001", "FMT")
      %{encoded: ObjectEncoder.encode(pfc)}
    end

    test "ST byte is 0x31", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x31
    end

    test "total size is 17 bytes", %{encoded: e} do
      assert byte_size(e) == 17
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0D", %{encoded: e} do
      <<_::binary-3, prefix, _::binary>> = e
      assert prefix == 0x0D
    end

    test "object name occupies bytes 4-11", %{encoded: e} do
      <<_::binary-4, name::binary-8, _::binary>> = e
      assert name == "SSGC0001"
    end

    test "ext is space-padded to 3 bytes", %{encoded: e} do
      <<_::binary-12, ext::binary-3, _::binary>> = e
      assert ext == "FMT"
    end

    test "sequence byte is 0x00", %{encoded: e} do
      <<_::binary-15, seq, _::binary>> = e
      assert seq == 0x00
    end

    test "type byte is 0x00 (page_format_object)", %{encoded: e} do
      <<_::binary-16, type>> = e
      assert type == 0x00
    end
  end

  describe "encode/1 — embedded call" do
    setup do
      pfc = PageFormatCall.new(:pc_prefix_program_embedded, "", "")
      %{encoded: ObjectEncoder.encode(pfc)}
    end

    test "ST byte is 0x31", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x31
    end

    test "total size is 6 bytes with no embedded object", %{encoded: e} do
      assert byte_size(e) == 6
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0F", %{encoded: e} do
      <<_::binary-3, prefix, _::binary>> = e
      assert prefix == 0x0F
    end

    test "offset is 0x0000", %{encoded: e} do
      <<_::binary-4, offset::16-little>> = e
      assert offset == 0
    end

    test "embedded object bytes appended" do
      pfc = PageFormatCall.new(:pc_prefix_program_embedded, "", "", <<0xAB, 0xCD>>)
      <<_::binary-6, tail::binary>> = ObjectEncoder.encode(pfc)
      assert tail == <<0xAB, 0xCD>>
    end
  end
end
