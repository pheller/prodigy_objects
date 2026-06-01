defmodule CustomTextTest do
  use ExUnit.Case

  describe "new/3" do
    test "stores reference_id, foreground, and background" do
      ct = CustomText.new(1, 0x0F, 0x00)
      assert ct.segment_type == :custom_text
      assert ct.reference_id == 1
      assert ct.foreground_color == 0x0F
      assert ct.background_color == 0x00
      assert ct.naplps == <<>>
    end
  end

  describe "new/4" do
    test "stores naplps data" do
      ct = CustomText.new(2, 0x07, 0x01, <<0xAB, 0xCD>>)
      assert ct.naplps == <<0xAB, 0xCD>>
    end
  end

  describe "encode/1" do
    test "ST byte is 0x0A" do
      ct = CustomText.new(1, 0x0F, 0x00)
      <<st, _::binary>> = ObjectEncoder.encode(ct)
      assert st == 0x0A
    end

    test "SL equals total encoded size" do
      ct = CustomText.new(1, 0x0F, 0x00)
      encoded = ObjectEncoder.encode(ct)
      <<_st, sl::16-little, _::binary>> = encoded
      assert sl == byte_size(encoded)
    end

    test "reference_id, foreground, background encoded as single bytes" do
      ct = CustomText.new(3, 0x07, 0x02)
      <<_st, _sl::16-little, ref_id, fg, bg, _naplps::binary>> = ObjectEncoder.encode(ct)
      assert ref_id == 3
      assert fg == 0x07
      assert bg == 0x02
    end

    test "naplps data appended at end" do
      naplps = <<0x11, 0x22, 0x33>>
      ct = CustomText.new(1, 0x0F, 0x00, naplps)
      encoded = ObjectEncoder.encode(ct)
      <<_st, _sl::16-little, _ref, _fg, _bg, tail::binary>> = encoded
      assert tail == naplps
    end

    test "no naplps produces 6-byte encoding" do
      ct = CustomText.new(1, 0x0F, 0x00)
      assert byte_size(ObjectEncoder.encode(ct)) == 6
    end
  end
end
