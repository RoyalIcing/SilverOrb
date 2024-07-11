defmodule MultiStepForm do
  # See: https://buildui.com/courses/framer-motion-recipes/multistep-wizard

  use Orb
  use SilverOrb.BumpAllocator
  use SilverOrb.StringBuilder

  global do
    @step 1
  end

  global :export_mutable do
    @step_count 4
  end

  defw(get_current_step(), I32, do: @step)

  defwp change_step(step: I32) do
    @step =
      if step < 1 do
        i32(1)
      else
        if(step > @step_count, do: @step_count, else: step)
      end
  end

  defw(next_step(), do: change_step(@step + 1))
  defw(previous_step(), do: change_step(@step - 1))
  defw(jump_to_step(step: I32), do: change_step(step))

  defw(to_string, StringBuilder, do: text_html())

  defw text_html, StringBuilder do
    build! do
      # "15 in hex is: "
      # append!(hex_upper: 15)

      "<h1>Step by step ✨</h1>\n"

      build_step(1)
      build_step(2)
      build_step(3)
      build_step(4)
      build_step(5)
    end
  end

  defwp build_step(step: I32), StringBuilder, current_step?: I32 do
    current_step? = step === Orb.Instruction.Global.Get.new(:i32, :step)
    # current_step? = @step === step

    build! do
      ~S|<div class="w-4 h-4 text-center |

      if current_step? do
        ~S|bg-blue-600 text-white|
      else
        ~S|text-black|
      end

      ~S|">|
      # Format.Decimal.u32(step)
      append!(decimal_u32: step)
      ~s|</div>\n|
    end
  end
end

defmodule SetCookie do
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie

  use Orb
  use SilverOrb.BumpAllocator
  use SilverOrb.StringBuilder
  use SilverOrb.Mem

  SilverOrb.BumpAllocator.export_alloc()

  # defmodule Constants do
  #   @constant_values I32.calculate_enum([:secure, :http_only])

  #   def get_len(value) do

  #   end
  # end

  # SilverOrb.Arena.def(NameInput, 1)
  # SilverOrb.Arena.def(ValueInput, 1)
  # SilverOrb.Arena.def(DomainInput, 1)
  # SilverOrb.Arena.def(PathInput, 1)

  global do
    @name ""
    @value ""
    @domain ""
    @path ""
    @secure 0
    @http_only 0
  end

  with do
    _ = @name
    _ = @value
    _ = @domain
    _ = @path
    _ = @secure
    _ = @http_only
  end

  defw set_cookie_name(new_value: Str) do
    @name = new_value
  end

  defw set_cookie_value(new_value: Str) do
    @value = new_value
  end

  defw set_domain(new_value: Str) do
    @domain = new_value
  end

  defw set_path(new_path: Str) do
    @path = new_path
  end

  defw set_secure() do
    @secure = 1
  end

  defw set_http_only() do
    @http_only = 1
  end

  defw to_string(), StringBuilder do
    build! do
      # @name <> ?= <> @value
      @name
      append!(ascii: ?=)
      @value

      if Memory.load!(I32.U8, @domain) !== 0 do
        # "; Domain=" <> @domain
        "; Domain="
        @domain
      end

      if Memory.load!(I32.U8, @path) !== 0 do
        "; Path="
        @path
      end

      if @secure do
        "; Secure"
      end

      if @http_only do
        "; HttpOnly"
      end
    end
  end
end

defmodule StringBuilderTest do
  use ExUnit.Case, async: true
  alias OrbWasmtime.Instance

  describe "MultiStepForm" do
    test "highlights first step" do
      wat = Orb.to_wat(MultiStepForm)
      # IO.puts(wat)
      instance = Instance.run(wat)

      {ptr, len} = Instance.call(instance, :to_string)
      html = Instance.read_memory(instance, ptr, len)

      assert html ==
               ~S"""
               <h1>Step by step ✨</h1>
               <div class="w-4 h-4 text-center bg-blue-600 text-white">1</div>
               <div class="w-4 h-4 text-center text-black">2</div>
               <div class="w-4 h-4 text-center text-black">3</div>
               <div class="w-4 h-4 text-center text-black">4</div>
               <div class="w-4 h-4 text-center text-black">5</div>
               """
    end

    test "can jump to 3rd step" do
      instance = Instance.run(MultiStepForm)
      # Instance.set_global(instance, :step_count, 3)
      Instance.call(instance, :jump_to_step, 3)

      {ptr, len} = Instance.call(instance, :to_string)
      html = Instance.read_memory(instance, ptr, len)

      assert html ==
               ~S"""
               <h1>Step by step ✨</h1>
               <div class="w-4 h-4 text-center text-black">1</div>
               <div class="w-4 h-4 text-center text-black">2</div>
               <div class="w-4 h-4 text-center bg-blue-600 text-white">3</div>
               <div class="w-4 h-4 text-center text-black">4</div>
               <div class="w-4 h-4 text-center text-black">5</div>
               """
    end
  end

  describe "Composable HTML components" do
    defmodule HelloWorldComponent do
      use Orb
      use SilverOrb.BumpAllocator
      use SilverOrb.StringBuilder

      defwp daytime?(hour_of_day: I32), I32 do
        hour_of_day >= 6 &&& hour_of_day <= 19
      end

      defw render(hour_of_day: I32), StringBuilder do
        StringBuilder.build! do
          "<h1>"

          if daytime?(hour_of_day) do
            "Hello 🌞 sunny world"
          else
            "Hello 🌛 moonlit world"
          end

          "</h1>\n"
        end
      end
    end

    defmodule DynamicHTMLPage do
      use Orb
      use SilverOrb.BumpAllocator
      use SilverOrb.StringBuilder

      Orb.include(HelloWorldComponent)

      global do
        @hour_of_day 8
      end

      defw set_hour_of_day(hour: I32) do
        @hour_of_day = hour
      end

      defw text_html(), StringBuilder do
        StringBuilder.build! do
          """
          <!doctype html>
          <meta charset="utf-8">
          """

          HelloWorldComponent.render(@hour_of_day)
        end
      end
    end

    test "renders html" do
      wat = Orb.to_wat(DynamicHTMLPage)
      # IO.puts(wat)
      instance = Instance.run(wat)

      get_html = fn ->
        {ptr, len} = Instance.call(instance, :text_html)
        Instance.read_memory(instance, ptr, len)
      end

      assert get_html.() ==
               ~S"""
               <!doctype html>
               <meta charset="utf-8">
               <h1>Hello 🌞 sunny world</h1>
               """

      Instance.call(instance, :set_hour_of_day, 2)

      assert get_html.() ==
               ~S"""
               <!doctype html>
               <meta charset="utf-8">
               <h1>Hello 🌛 moonlit world</h1>
               """

      Enum.each(0..10000, fn _ ->
        assert get_html.() ==
                 ~S"""
                 <!doctype html>
                 <meta charset="utf-8">
                 <h1>Hello 🌛 moonlit world</h1>
                 """
      end)
    end
  end

  describe "SetCookie" do
    @describetag :skip
    test "wasm size" do
      assert byte_size(OrbWasmtime.Wasm.to_wasm(SetCookie)) == 759
    end

    test "name and value" do
      wat = SetCookie.to_wat()
      inst = Instance.run(wat)
      # put_in(inst[:name], "foo")
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      # Instance.call(inst, :"name=", Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))

      # inst[{String, :to_string}]
      assert Instance.call_reading_string(inst, :to_string) == "foo=value"
    end

    test "domain" do
      inst = Instance.run(SetCookie)

      # Instance.write_string!(inst, "foo", :cookie_name_range)

      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; Domain=foo.example.com"
    end

    test "HttpOnly" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; HttpOnly"
    end

    test "HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)
      assert Instance.call_reading_string(inst, :to_string) == "foo=value; Secure; HttpOnly"
    end

    test "Domain HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)

      assert Instance.call_reading_string(inst, :to_string) ==
               "foo=value; Domain=foo.example.com; Secure; HttpOnly"
    end

    test "Domain Path HttpOnly Secure" do
      inst = Instance.run(SetCookie)
      Instance.call(inst, :set_cookie_name, Instance.alloc_string(inst, "foo"))
      Instance.call(inst, :set_cookie_value, Instance.alloc_string(inst, "value"))
      Instance.call(inst, :set_domain, Instance.alloc_string(inst, "foo.example.com"))
      Instance.call(inst, :set_path, Instance.alloc_string(inst, "/"))
      Instance.call(inst, :set_http_only)
      Instance.call(inst, :set_secure)

      assert Instance.call_reading_string(inst, :to_string) ==
               "foo=value; Domain=foo.example.com; Path=/; Secure; HttpOnly"
    end
  end
end
