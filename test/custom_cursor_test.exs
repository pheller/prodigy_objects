defmodule CustomCursorTest do
  use ExUnit.Case

  describe "new/3" do
    test "stores cursor_id, size, and naplps" do
      cc = CustomCursor.new(1, {20, 10}, <<0xAB>>)
      assert cc.segment_type == :custom_cursor
      assert cc.cursor_id == 1
      assert cc.cursor_size == {20, 10}
      assert cc.naplps == <<0xAB>>
    end
  end

  describe "encode/1" do
    test "ST byte is 0x0B" do
      cc = CustomCursor.new(1, {20, 10}, <<>>)
      <<st, _::binary>> = ObjectEncoder.encode(cc)
      assert st == 0x0B
    end

    test "SL equals total encoded size" do
      cc = CustomCursor.new(1, {20, 10}, <<0x01, 0x02>>)
      encoded = ObjectEncoder.encode(cc)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "cursor_id encoded as single byte" do
      cc = CustomCursor.new(5, {10, 10}, <<>>)
      <<_st, _sl::16-little, cursor_id, _::binary>> = ObjectEncoder.encode(cc)
      assert cursor_id == 5
    end

    test "cursor size occupies 3 bytes in NAPLPS format" do
      cc = CustomCursor.new(1, {20, 10}, <<>>)
      <<_st, _sl::16-little, _id, size::binary-3, _::binary>> = ObjectEncoder.encode(cc)
      assert size == ObjectUtils.naplps_coords({20, 10})
    end

    test "naplps data appended after size" do
      naplps = <<0xDE, 0xAD, 0xBE>>
      cc = CustomCursor.new(1, {10, 10}, naplps)
      encoded = ObjectEncoder.encode(cc)
      <<_st, _sl::16-little, _id, _size::binary-3, tail::binary>> = encoded
      assert tail == naplps
    end

    test "no naplps produces 7-byte encoding" do
      cc = CustomCursor.new(1, {10, 10}, <<>>)
      assert byte_size(ObjectEncoder.encode(cc)) == 7
    end
  end
end
