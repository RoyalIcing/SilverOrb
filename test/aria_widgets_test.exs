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

  defw focus_next_item() do
    @active_item_index = @active_item_index + 1

    if @active_item_index > @item_count do
      @active_item_index = 1
    end

    @focus_enum = FocusEnum.menu()
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
      ~S|<button type="button" data-action="toggle" data-keydown-arrow-down id="|
      button_id()
      ~S|" aria-haspopup="true" aria-expanded="|

      if open?() do
        "true"
      else
        "false"
      end

      ~S|" aria-controls="|
      menu_id()
      ~S|">|
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

      ~S|">|
      "\n"

      loop EachItem, result: StringBuilder do
        menu_item(i)

        i = i + 1

        if i <= @item_count do
          EachItem.continue()
        end
      end

      ~S|</ul>|
      "\n"
    end
  end

  defwp menu_item(i: I32), StringBuilder do
    build! do
      ~S|<li role="menuitem" id="|
      menu_item_id(i)
      ~S|" data-action="activate_item:[|
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
      button()
      menu_list()
    end
  end

  defw text_css(), StringBuilder do
    build! do
      ~S"""
      menu-button button { background-color: var(--MenuButton-background); }
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

  # |> export("text/html")
end

defmodule AriaWidgetsTest do
  use ExUnit.Case, async: true
  alias OrbWasmtime.Instance

  defmacrop sigil_H({:<<>>, meta, [expr]}, []) do
    EEx.compile_string(expr, indentation: meta[:indentation] || 0)
  end

  describe "MenuButton" do
    setup do
      wat = Orb.to_wat(MenuButton)
      # IO.puts(wat)
      instance = Instance.run(wat)
      %{instance: instance}
    end

    test "initial html", %{instance: instance} do
      html = read_string(instance, :text_html)

      assert html === ~H"""
             <button type="button" data-action="toggle" data-keydown-arrow-down id="menubutton:1" aria-haspopup="true" aria-expanded="false" aria-controls="menu:1">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="">
             <li role="menuitem" id="menuitem:1.1" data-action="activate_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="activate_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="activate_item:[3]">Action 3</li>
             </ul>
             """

      assert read_string(instance, :focus_id) === ""
    end

    test "read ids", %{instance: instance} do
      assert read_string(instance, :button_id) === "menubutton:1"
      assert read_string(instance, :menu_id) === "menu:1"
    end

    test "when changing id suffix", %{instance: instance} do
      Instance.set_global(instance, :id_suffix, 99)
      assert read_string(instance, :button_id) === "menubutton:99"
      assert read_string(instance, :menu_id) === "menu:99"
      assert read_string(instance, :text_html) =~ ~S|id="menubutton:99"|
      assert read_string(instance, :text_html) =~ ~S|id="menu:99"|
    end

    test "when open", %{instance: instance} do
      Instance.call(instance, :open)
      html = read_string(instance, :text_html)

      assert html === ~H"""
             <button type="button" data-action="toggle" data-keydown-arrow-down id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="menuitem:1.1">
             <li role="menuitem" id="menuitem:1.1" data-action="activate_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="activate_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="activate_item:[3]">Action 3</li>
             </ul>
             """

      assert read_string(instance, :focus_id) === "menu:1"
    end

    test "key events", %{instance: instance} do
      Instance.call(instance, :toggle)

      Instance.call(instance, :focus_next_item)
      assert read_string(instance, :focus_id) === "menu:1"

      assert read_string(instance, :text_html) === ~H"""
             <button type="button" data-action="toggle" data-keydown-arrow-down id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="menuitem:1.2">
             <li role="menuitem" id="menuitem:1.1" data-action="activate_item:[1]">Action 1</li>
             <li role="menuitem" id="menuitem:1.2" data-action="activate_item:[2]">Action 2</li>
             <li role="menuitem" id="menuitem:1.3" data-action="activate_item:[3]">Action 3</li>
             </ul>
             """
    end

    test "focus next wraps", %{instance: instance} do
      Instance.call(instance, :toggle)
      assert read_string(instance, :text_html) =~ ~S|aria-activedescendant="menuitem:1.1"|
      Instance.call(instance, :focus_next_item)
      assert read_string(instance, :text_html) =~ ~S|aria-activedescendant="menuitem:1.2"|
      Instance.call(instance, :focus_next_item)
      assert read_string(instance, :text_html) =~ ~S|aria-activedescendant="menuitem:1.3"|
      Instance.call(instance, :focus_next_item)
      assert read_string(instance, :text_html) =~ ~S|aria-activedescendant="menuitem:1.1"|
    end
  end

  defp read_string(instance, f) when is_atom(f) do
    {ptr, len} = Instance.call(instance, f)
    Instance.read_memory(instance, ptr, len)
  end
end
