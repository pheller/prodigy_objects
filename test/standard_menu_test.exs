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
    # CF4J has NO numbered choices. Its menu exists only to name its successor,
    # so the OBJID goes in next_page and the choice/action lists stay empty.
    next_page =
      StandardMenu.objid("NH000000PG", 1, 4) <>
        StandardMenu.destination(<<0x58, 0x00, 0x01>> <> StandardMenu.objid("NH00CF4KB", 1, 8))

    built =
      StandardMenu.menu_params(mode: 3, pages: 0, next_page: next_page)
      |> ObjectUtils.make_params_buffer()

    assert built == @recovered
  end

  test "the area length counts itself" do
    built = StandardMenu.menu_params() |> ObjectUtils.make_params_buffer()
    <<len::16-big, _::binary>> = built
    assert len == byte_size(built)
  end

  test "choices are mapped to their offsets in the action list" do
    a = StandardMenu.objid("NH00A001B", 1, 8)
    b = StandardMenu.objid("NH00A002B", 1, 8)
    [_p1, _p2, _p3, p4, _p5, p6] = StandardMenu.menu_params(actions: [a, b])

    # Each action entry is [action][type] + target; P6 prefixes a PEV byte.
    entry = 2 + byte_size(a)
    <<0x01, _len::16, 1, off1::16, 2, off2::16>> = p4
    assert off1 == 0
    assert off2 == 1 + entry

    <<0x01, len6::16, body::binary>> = p6
    assert byte_size(body) == len6
    assert binary_part(body, 0, 1) == <<1>>
  end

  test "a menu with no choices still declares its successor" do
    [_p1, _p2, p3, p4, _p5, p6] = StandardMenu.menu_params(next_page: <<0xAA, 0xBB>>)
    assert p3 == <<0x00, 0xAA, 0xBB>>
    # empty choice map and a bare terminator, as CF4J carries
    assert p4 == <<0x01, 0x00, 0x00>>
    assert p6 == <<0x01, 0x00, 0x01, 0x00>>
  end
end
