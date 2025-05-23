defmodule MenuButton do
  # See: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/examples/menu-button-actions-active-descendant/

  use Orb
  use SilverOrb.StringBuilder

  defmodule FocusEnum do
    def none(), do: 0
    def menu(), do: 1
    def button(), do: 2
  end

  global do
    @active_item_index 0
    @focus_enum FocusEnum.none()
  end

  global :export_mutable do
    @id_suffix 1
    @item_count 3
  end

  defw open?(), I32 do
    @active_item_index > 0
  end

  defw open() do
    if @item_count > 0 do
      @active_item_index = 1
      @focus_enum = FocusEnum.menu()
    end
  end

  defw close() do
    @active_item_index = 0
    @focus_enum = FocusEnum.button()
  end

  defw toggle() do
    if @active_item_index do
      close()
    else
      open()
    end
  end

  defw focus_item(index: I32) do
    @active_item_index =
      if index > @item_count do
        i32(1)
      else
        if index <= 0 do
          @item_count
        else
          index
        end
      end

    @focus_enum = FocusEnum.menu()
  end

  defw focus_previous_item() do
    focus_item(@active_item_index - 1)
  end

  defw focus_next_item() do
    focus_item(@active_item_index + 1)
  end

  defw button_id(), StringBuilder do
    build! do
      "menubutton:"
      append!(decimal_u32: @id_suffix)
    end
  end

  defw menu_id(), StringBuilder do
    build! do
      "menu:"
      append!(decimal_u32: @id_suffix)
    end
  end

  defw menu_item_id(index: I32), StringBuilder do
    build! do
      "menuitem:"
      append!(decimal_u32: @id_suffix)
      "."
      append!(decimal_u32: index)
    end
  end

  defwp button(), StringBuilder do
    build! do
      ~S|<button type="button" id="|
      button_id()
      ~S|" aria-haspopup="true" aria-expanded="|

      if open?() do
        "true"
      else
        "false"
      end

      ~S|" aria-controls="|
      menu_id()

      ~S|" data-action="toggle" data-keydown-arrow-down data-keydown-arrow-up="focus_previous_item">|

      "\n"
    end
  end

  defwp menu_list(), StringBuilder, i: I32 do
    i = 1

    build! do
      ~S|<ul role="menu" id="|
      menu_id()
      ~S|" tabindex="-1" aria-labelledby="|
      button_id()
      ~S|" aria-activedescendant="|

      if @active_item_index > 0 do
        menu_item_id(@active_item_index)
      end

      ~S|" data-keydown-escape="close" data-keydown-arrow-down="focus_previous_item" data-keydown-arrow-down="focus_next_item">|
      "\n"

      loop EachItem, result: StringBuilder do
        menu_item(i)

        i = i + 1

        if i <= @item_count do
          EachItem.continue()
        end

        # EachItem.continue() when i <= @item_count
        # continue(EachItem) when i <= @item_count
      end

      ~S|</ul>|
      "\n"
    end
  end

  defwp menu_item(i: I32), StringBuilder do
    build! do
      ~S|<li role="menuitem" id="|
      menu_item_id(i)
      ~S|" data-action="select_item:[|
      append!(decimal_u32: i)
      ~S|]" data-pointerover="focus_item:[|
      append!(decimal_u32: i)
      ~S|]">|
      ~S|Action |
      append!(decimal_u32: i)
      ~S|</li>|
      "\n"
    end
  end

  # @export "text/html"
  defw text_html(), StringBuilder do
    build! do
      "<lipid-menu-button>\n"
      button()
      menu_list()
      "</lipid-menu-button>\n"
    end
  end

  defw text_css(), StringBuilder do
    build! do
      ~S"""
      lipid-menu-button button { background-color: var(--LipidMenuButton-background); }
      """
    end
  end

  defw focus_id(), StringBuilder do
    build! do
      if @focus_enum === 1 do
        menu_id()
      else
        if @focus_enum === 2 do
          button_id()
        else
          ""
        end
      end
    end
  end

  defw application_javascript(), StringBuilder do
    build! do
      ~S"""
      // data-keydown-arrow-down
      """
    end
  end
end

defmodule AriaWidgetsTest do
  use WasmexCase, async: true

  defmacrop sigil_H({:<<>>, meta, [expr]}, []) do
    EEx.compile_string(expr, indentation: meta[:indentation] || 0)
  end

  describe "MenuButton" do
    @describetag wat: Orb.to_wat(MenuButton)

    defp read_string(call_function, read_binary, f) when is_atom(f) do
      {:ok, [ptr, len]} = call_function.(f, [])
      read_binary.(ptr, len)
    end

    test "initial html", %{call_function: call_function, read_binary: read_binary} do
      html = read_string(call_function, read_binary, :text_html)

      assert html === ~H"""
             <lipid-menu-button>
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="false" aria-controls="menu:1" data-action="toggle" data-keydown-arrow-down data-keydown-arrow-up="focus_previous_item">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="" data-keydown-escape="close" data-keydown-arrow-down="focus_previous_item" data-keydown-arrow-down="focus_next_item">
             <li role="menuitem" id="menuitem:1.1" data-action="select_item:[1]" data-pointerover="focus_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="select_item:[2]" data-pointerover="focus_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="select_item:[3]" data-pointerover="focus_item:[3]">Action 3</li>
             </ul>
             </lipid-menu-button>
             """

      assert read_string(call_function, read_binary, :focus_id) === ""
    end

    test "can read ids", %{call_function: call_function, read_binary: read_binary} do
      assert read_string(call_function, read_binary, :button_id) === "menubutton:1"
      assert read_string(call_function, read_binary, :menu_id) === "menu:1"
    end

    test "when changing id suffix", %{
      call_function: call_function,
      read_binary: read_binary,
      set_global: set_global
    } do
      set_global.("id_suffix", 99)
      assert read_string(call_function, read_binary, :button_id) === "menubutton:99"
      assert read_string(call_function, read_binary, :menu_id) === "menu:99"
      assert read_string(call_function, read_binary, :text_html) =~ ~S|id="menubutton:99"|
      assert read_string(call_function, read_binary, :text_html) =~ ~S|id="menu:99"|
    end

    test "when open", %{call_function: call_function, read_binary: read_binary} do
      {:ok, []} = call_function.(:open, [])
      html = read_string(call_function, read_binary, :text_html)

      assert html === ~H"""
             <lipid-menu-button>
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1" data-action="toggle" data-keydown-arrow-down data-keydown-arrow-up="focus_previous_item">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="menuitem:1.1" data-keydown-escape="close" data-keydown-arrow-down="focus_previous_item" data-keydown-arrow-down="focus_next_item">
             <li role="menuitem" id="menuitem:1.1" data-action="select_item:[1]" data-pointerover="focus_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="select_item:[2]" data-pointerover="focus_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="select_item:[3]" data-pointerover="focus_item:[3]">Action 3</li>
             </ul>
             </lipid-menu-button>
             """

      assert read_string(call_function, read_binary, :focus_id) === "menu:1"
    end

    test "key events", %{call_function: call_function, read_binary: read_binary} do
      {:ok, []} = call_function.(:toggle, [])

      {:ok, []} = call_function.(:focus_next_item, [])
      assert read_string(call_function, read_binary, :focus_id) === "menu:1"

      assert read_string(call_function, read_binary, :text_html) === ~H"""
             <lipid-menu-button>
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1" data-action="toggle" data-keydown-arrow-down data-keydown-arrow-up="focus_previous_item">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="menuitem:1.2" data-keydown-escape="close" data-keydown-arrow-down="focus_previous_item" data-keydown-arrow-down="focus_next_item">
             <li role="menuitem" id="menuitem:1.1" data-action="select_item:[1]" data-pointerover="focus_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="select_item:[2]" data-pointerover="focus_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="select_item:[3]" data-pointerover="focus_item:[3]">Action 3</li>
             </ul>
             </lipid-menu-button>
             """
    end

    test "button arrow up", %{call_function: call_function, read_binary: read_binary} do
      {:ok, []} = call_function.(:focus_previous_item, [])
      assert read_string(call_function, read_binary, :focus_id) === "menu:1"

      assert read_string(call_function, read_binary, :text_html) === ~H"""
             <lipid-menu-button>
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1" data-action="toggle" data-keydown-arrow-down data-keydown-arrow-up="focus_previous_item">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="menuitem:1.3" data-keydown-escape="close" data-keydown-arrow-down="focus_previous_item" data-keydown-arrow-down="focus_next_item">
             <li role="menuitem" id="menuitem:1.1" data-action="select_item:[1]" data-pointerover="focus_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="select_item:[2]" data-pointerover="focus_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="select_item:[3]" data-pointerover="focus_item:[3]">Action 3</li>
             </ul>
             </lipid-menu-button>
             """
    end

    test "focus next/previous wraps", %{call_function: call_function, read_binary: read_binary} do
      {:ok, []} = call_function.(:toggle, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.1"|

      {:ok, []} = call_function.(:focus_next_item, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.2"|

      {:ok, []} = call_function.(:focus_next_item, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.3"|

      {:ok, []} = call_function.(:focus_next_item, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.1"|

      {:ok, []} = call_function.(:focus_previous_item, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.3"|

      {:ok, []} = call_function.(:focus_previous_item, [])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.2"|
    end

    test "menuitem pointerover", %{call_function: call_function, read_binary: read_binary} do
      {:ok, []} = call_function.(:focus_item, [2])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.2"|

      {:ok, []} = call_function.(:focus_item, [-1])

      assert read_string(call_function, read_binary, :text_html) =~
               ~S|aria-activedescendant="menuitem:1.3"|
    end
  end
end
