defmodule MenuButton do
  # See: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/examples/menu-button-actions-active-descendant/

  use Orb
  use SilverOrb.StringBuilder

  global do
    @expanded? 0
  end

  global :export_mutable do
    @id_suffix 1
    @menu_item_count 4
  end

  defw(get_expanded?(), I32, do: @expanded?)

  defw open() do
    @expanded? = 1
  end

  defw close() do
    @expanded? = 0
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

      if @expanded? do
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
      ~S|" aria-activedescendant="">|
      "\n"

      loop EachItem, result: StringBuilder do
        menu_item(i)

        i = i + 1

        if i <= @menu_item_count do
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
      ~S|">|
      ~S|Action |
      append!(decimal_u32: i)
      ~S|</li>|
      "\n"
    end
  end

  # @export "text/html"
  defw text_html, StringBuilder do
    build! do
      button()
      menu_list()
    end
  end

  # |> export("text/html")

  # defwp build_item(step: I32), StringBuilder, current_step?: I32 do
  #   current_step? = step === Orb.Instruction.Global.Get.new(:i32, :step)
  #   # current_step? = @step === step

  #   build! do
  #     ~S|<div class="w-4 h-4 text-center |

  #     if current_step? do
  #       ~S|bg-blue-600 text-white|
  #     else
  #       ~S|text-black|
  #     end

  #     ~S|">|
  #     # Format.Decimal.u32(step)
  #     # {:decimal_u32, step}
  #     # step
  #     append!(decimal_u32: step)
  #     ~s|</div>\n|
  #   end
  # end
end

defmodule AriaWidgetsTest do
  use ExUnit.Case, async: true
  alias OrbWasmtime.Instance

  defmacrop sigil_H({:<<>>, meta, [expr]}, []) do
    # expr
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
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="false" aria-controls="menu:1">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="">
             <li role="menuitem" id="menuitem:1.1">Action 1</li>
             <li role="menuitem" id="menuitem:1.2">Action 2</li>
             <li role="menuitem" id="menuitem:1.3">Action 3</li>
             <li role="menuitem" id="menuitem:1.4">Action 4</li>
             </ul>
             """
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
             <button type="button" id="menubutton:1" aria-haspopup="true" aria-expanded="true" aria-controls="menu:1">
             <ul role="menu" id="menu:1" tabindex="-1" aria-labelledby="menubutton:1" aria-activedescendant="">
             <li role="menuitem" id="menuitem:1.1">Action 1</li>
             <li role="menuitem" id="menuitem:1.2">Action 2</li>
             <li role="menuitem" id="menuitem:1.3">Action 3</li>
             <li role="menuitem" id="menuitem:1.4">Action 4</li>
             </ul>
             """
    end
  end

  defp read_string(instance, f) when is_atom(f) do
    {ptr, len} = Instance.call(instance, f)
    Instance.read_memory(instance, ptr, len)
  end
end
