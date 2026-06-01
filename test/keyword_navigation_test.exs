defmodule KeywordNavigationTest do
  use ExUnit.Case

  # Layout with no optional fields (16 bytes):
  #   0    ST           0x71
  #   1-2  SL           16 (little-endian)
  #   3-15 prev_menu    13 spaces
  #
  # Layout with optional fields (42 bytes):
  #   0    ST           0x71
  #   1-2  SL           42 (little-endian)
  #   3-15 prev_menu    13 spaces
  #  16-28 guide_bfd    13 bytes (padded)
  #  29-41 current_kw   13 bytes (padded)

  describe "new/0" do
    test "segment_type is :keyword_navigation" do
      kn = KeywordNavigation.new()
      assert kn.segment_type == :keyword_navigation
    end

    test "prev_menu is 13 spaces" do
      kn = KeywordNavigation.new()
      assert kn.prev_menu == String.duplicate(" ", 13)
    end

    test "guide_bfd and current_keyword are nil" do
      kn = KeywordNavigation.new()
      assert kn.guide_bfd == nil
      assert kn.current_keyword == nil
    end
  end

  describe "new/2" do
    test "stores guide_bfd padded to 13 bytes" do
      kn = KeywordNavigation.new("111000001.BFD  ", "GETFIT")
      assert byte_size(kn.guide_bfd) == 13
    end

    test "stores current_keyword padded to 13 bytes" do
      kn = KeywordNavigation.new("111000001.BFD  ", "GETFIT")
      assert byte_size(kn.current_keyword) == 13
    end
  end

  describe "encode/1 — no optional fields" do
    setup do
      kn = KeywordNavigation.new()
      %{encoded: ObjectEncoder.encode(kn)}
    end

    test "ST byte is 0x71", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x71
    end

    test "total size is 16 bytes", %{encoded: e} do
      assert byte_size(e) == 16
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prev_menu is 13 spaces at bytes 3-15", %{encoded: e} do
      <<_::binary-3, prev_menu::binary-13>> = e
      assert prev_menu == String.duplicate(" ", 13)
    end
  end

  describe "encode/1 — with optional fields" do
    setup do
      kn = KeywordNavigation.new("111000001.BFD  ", "GETFIT")
      %{encoded: ObjectEncoder.encode(kn), kn: kn}
    end

    test "ST byte is 0x71", %{encoded: e} do
      <<st, _::binary>> = e
      assert st == 0x71
    end

    test "total size is 42 bytes", %{encoded: e} do
      assert byte_size(e) == 42
    end

    test "SL equals total encoded size", %{encoded: e} do
      <<_st, sl::16-little, _::binary>> = e
      assert sl == byte_size(e)
    end

    test "prev_menu at bytes 3-15", %{encoded: e} do
      <<_::binary-3, prev_menu::binary-13, _::binary>> = e
      assert prev_menu == String.duplicate(" ", 13)
    end

    test "guide_bfd at bytes 16-28", %{encoded: e, kn: kn} do
      <<_::binary-16, guide_bfd::binary-13, _::binary>> = e
      assert guide_bfd == kn.guide_bfd
    end

    test "current_keyword at bytes 29-41", %{encoded: e, kn: kn} do
      <<_::binary-29, current_keyword::binary-13>> = e
      assert current_keyword == kn.current_keyword
    end
  end
end
