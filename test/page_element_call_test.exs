defmodule PageElementCallTest do
  use ExUnit.Case

  # External call — current state of page_element_call.ex:
  # The segment_length field is calculated as 19 (counting 13 bytes for OBJID),
  # but only 11 bytes of OBJID are written (name 8 + ext 3; the seq and type
  # bytes are currently commented out). So the encoded binary is 17 bytes while
  # the SL field says 19. See the comment in page_element_call.ex.
  #
  # Embedded call layout (8 bytes, no embedded object):
  #   0    ST           0x21
  #   1-2  SL           8 (little-endian)
  #   3    partition_id
  #   4    priority     0x00
  #   5    prefix       0x0F
  #   6-7  offset       0x0000

  describe "new/4" do
    test "stores partition_id, prefix, name, ext" do
      pec = PageElementCall.new(2, :pc_prefix_program_call, "SSGC0001", "BB1")
      assert pec.segment_type == :page_element_call
      assert pec.partition_id == 2
      assert pec.priority == 0x00
      assert pec.prefix == :pc_prefix_program_call
      assert pec.object_name == "SSGC0001"
      assert pec.object_ext == "BB1"
    end
  end

  describe "encode/1 — external call" do
    setup do
      pec = PageElementCall.new(1, :pc_prefix_program_call, "SSGC0001", "BB1")
      %{encoded: ObjectEncoder.encode(pec)}
    end

    test "ST byte is 0x21", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x21
    end

    test "prefix byte is 0x0D", %{encoded: e} do
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0D
    end

    test "partition_id is encoded at byte 3", %{encoded: e} do
      <<_::binary-3, partition_id, _::binary>> = e
      assert partition_id == 1
    end

    test "priority byte is 0x00", %{encoded: e} do
      <<_::binary-4, priority, _::binary>> = e
      assert priority == 0x00
    end

    test "object name occupies 8 bytes after prefix", %{encoded: e} do
      <<_::binary-6, name::binary-8, _::binary>> = e
      assert name == "SSGC0001"
    end

    test "object ext occupies 3 bytes after name", %{encoded: e} do
      <<_::binary-14, ext::binary-3>> = e
      assert ext == "BB1"
    end
  end

  describe "encode/1 — embedded call" do
    setup do
      pec = PageElementCall.new(2, :pc_prefix_program_embedded, "", "")
      %{encoded: ObjectEncoder.encode(pec)}
    end

    test "ST byte is 0x21", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x21
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0F", %{encoded: e} do
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0F
    end

    test "offset is 0x0000", %{encoded: e} do
      <<_::binary-6, offset::16-little>> = e
      assert offset == 0
    end

    test "embedded object bytes appended" do
      pec = PageElementCall.new(1, :pc_prefix_program_embedded, "", "", <<0x01, 0x02>>)
      <<_::binary-8, tail::binary>> = ObjectEncoder.encode(pec)
      assert tail == <<0x01, 0x02>>
    end
  end
end
