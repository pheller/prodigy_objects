defmodule PageElementSelectorTest do
  use ExUnit.Case

  # External call layout (21 bytes with empty params):
  #   0    ST           0x20
  #   1-2  SL           21 (little-endian)
  #   3    partition_id
  #   4    priority     0x00
  #   5    prefix       0x0D
  #   6-13 name         8 bytes
  #  14-16 ext          3 bytes
  #    17  seq          0x00
  #    18  type         0x0C (program_object)
  #  19-20 params       <<0,2>> (empty PLEN)

  describe "new/5" do
    test "stores all fields" do
      pes = PageElementSelector.new(3, :pc_prefix_program_call,
                                   "SSGCA005", "PGM", [])
      assert pes.segment_type == :page_element_selector
      assert pes.partition_id == 3
      assert pes.priority == 0x00
      assert pes.prefix == :pc_prefix_program_call
      assert pes.object_name == "SSGCA005"
      assert pes.parameters == []
    end
  end

  describe "encode/1 — external call" do
    setup do
      pes = PageElementSelector.new(3, :pc_prefix_program_call, "SSGCA005", "PGM", [])
      %{encoded: ObjectEncoder.encode(pes)}
    end

    test "ST byte is 0x20", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x20
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "partition_id at byte 3", %{encoded: e} do
      <<_::binary-3, partition_id, _::binary>> = e
      assert partition_id == 3
    end

    test "priority byte is 0x00", %{encoded: e} do
      <<_::binary-4, priority, _::binary>> = e
      assert priority == 0x00
    end

    test "prefix byte is 0x0D", %{encoded: e} do
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0D
    end

    test "type byte is 0x0C (selector calls a program object)", %{encoded: e} do
      <<_::binary-18, type, _::binary>> = e
      assert type == 0x0C
    end

    test "parameters appended" do
      pes = PageElementSelector.new(3, :pc_prefix_program_call,
                                   "SSGCA005", "PGM", [<<"TOD">>])
      pes_empty = PageElementSelector.new(3, :pc_prefix_program_call,
                                         "SSGCA005", "PGM", [])
      assert byte_size(ObjectEncoder.encode(pes)) >
               byte_size(ObjectEncoder.encode(pes_empty))
    end
  end

  describe "encode/1 — embedded call" do
    setup do
      pes = PageElementSelector.new(3, :pc_prefix_program_embedded, "", "", [])
      %{encoded: ObjectEncoder.encode(pes)}
    end

    test "ST byte is 0x20", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x20
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prefix byte is 0x0F", %{encoded: e} do
      <<_::binary-5, prefix, _::binary>> = e
      assert prefix == 0x0F
    end
  end
end
