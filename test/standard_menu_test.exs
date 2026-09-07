defmodule StandardMenuTest do
  use ExUnit.Case
  doctest StandardMenu

  # The parameter block of NH00CF4JB's standard-menu call, recovered from the
  # service. Everything from the 2-byte area length onward.
  @recovered <<
    0x00,
    0x3D,
    0x00,
    0x03,
    0x00,
    0x00,
    0x03,
    0x03,
    0x00,
    0x23,
    0x00,
    "NH000000PG "::binary,
    0x01,
    0x04,
    ?P,
    0x00,
    0x10,
    0x58,
    0x00,
    0x01,
    "NH00CF4KB  "::binary,
    0x01,
    0x08,
    0x00,
    0x05,
    0x01,
    0x00,
    0x00,
    0x00,
    0x07,
    0x01,
    0x00,
    0x02,
    0x00,
    0x00,
    0x00,
    0x06,
    0x01,
    0x00,
    0x01,
    0x00
  >>

  test "objid pads the name to eleven characters" do
    assert StandardMenu.objid("NH00CF4KB", 1, 8) ==
             <<"NH00CF4KB  ", 0x01, 0x08>>

    assert byte_size(StandardMenu.objid("X", 0, 4)) == 13
  end

  test "destination tags and length-prefixes its payload" do
    assert StandardMenu.destination(<<0xAA, 0xBB>>) == <<?P, 0x00, 0x02, 0xAA, 0xBB>>
  end

  test "reproduces the recovered NH00CF4JB parameter block byte for byte" do
    action =
      StandardMenu.objid("NH000000PG", 1, 4) <>
        StandardMenu.destination(<<0x58, 0x00, 0x01>> <> StandardMenu.objid("NH00CF4KB", 1, 8))

    built =
      StandardMenu.menu_params(mode: 3, pages: 0, actions: [action])
      |> ObjectUtils.make_params_buffer()

    assert built == @recovered
  end

  test "the area length counts itself" do
    built = StandardMenu.menu_params() |> ObjectUtils.make_params_buffer()
    <<len::16-big, _::binary>> = built
    assert len == byte_size(built)
  end

  test "several actions concatenate into P3" do
    a = StandardMenu.objid("NH000000PG", 1, 4)
    built = StandardMenu.menu_params(actions: [a, a]) |> ObjectUtils.make_params_buffer()
    # P1 (3) + P2 (3) + P3 (2 + 1 + 26) + P4 (5) + P5 (7) + P6 (6) + area (2)
    assert byte_size(built) == 2 + 3 + 3 + 29 + 5 + 7 + 6
  end
end
