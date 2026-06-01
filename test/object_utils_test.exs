defmodule ObjectUtilsTest do
  use ExUnit.Case

  describe "edit_length/2" do
    test "pads a short string with spaces" do
      assert ObjectUtils.edit_length("AB", 5) == "AB   "
    end

    test "leaves an exact-length string unchanged" do
      assert ObjectUtils.edit_length("SSGC0001", 8) == "SSGC0001"
    end

    test "truncates a string that is too long" do
      assert ObjectUtils.edit_length("TOOLONGSTRING", 8) == "TOOLONGS"
    end

    test "handles an empty string" do
      assert ObjectUtils.edit_length("", 3) == "   "
    end
  end

  describe "naplps_coords/1" do
    test "returns a 3-byte binary" do
      assert byte_size(ObjectUtils.naplps_coords({0, 0})) == 3
      assert byte_size(ObjectUtils.naplps_coords({120, 100})) == 3
    end

    test "different coordinates produce different results" do
      refute ObjectUtils.naplps_coords({10, 20}) == ObjectUtils.naplps_coords({30, 40})
    end

    test "same coordinates always produce the same result" do
      assert ObjectUtils.naplps_coords({64, 128}) == ObjectUtils.naplps_coords({64, 128})
    end
  end

  describe "make_params_buffer/1" do
    test "empty list produces 2-byte PLEN-only buffer" do
      # PLEN = 2 (big-endian), no param data
      assert ObjectUtils.make_params_buffer([]) == <<0, 2>>
    end

    test "one binary parameter" do
      # P1LEN = 2+2=4, value = <<1,2>>, PLEN = 2+4=6
      assert ObjectUtils.make_params_buffer([<<1, 2>>]) == <<0, 6, 0, 4, 1, 2>>
    end

    test "null placeholder parameter" do
      # Null param: P1LEN = 3, value = <<0x00>>; PLEN = 2+3=5
      assert ObjectUtils.make_params_buffer([<<>>]) == <<0, 5, 0, 3, 0>>
    end

    test "multiple parameters" do
      # P1LEN = 2+1=3 (<<0xAA>>), P2LEN = 2+1=3 (<<0xBB>>), PLEN = 2+3+3=8
      assert ObjectUtils.make_params_buffer([<<0xAA>>, <<0xBB>>]) ==
               <<0, 8, 0, 3, 0xAA, 0, 3, 0xBB>>
    end

    test "null placeholder preserves positional slot between real params" do
      # [<<1>>, <<>>, <<3>>]: P1LEN=3, P2LEN=3(null), P3LEN=3; PLEN=2+3+3+3=11
      assert ObjectUtils.make_params_buffer([<<1>>, <<>>, <<3>>]) ==
               <<0, 11, 0, 3, 1, 0, 3, 0, 0, 3, 3>>
    end
  end
end
