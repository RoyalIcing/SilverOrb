defmodule MultiStepForm do
  # See: https://buildui.com/courses/framer-motion-recipes/multistep-wizard

  use Orb
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
      # {:decimal_u32, step}
      # step
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
  use WasmexCase, async: true

  setup_all do
    wat = Orb.to_wat(MultiStepForm)
    {:ok, wasm} = Wasmex.Wat.to_wasm(wat)

    %{wat: wat, wasm: wasm}
  end

  describe "MultiStepForm" do
    test "highlights first step", %{wat: wat, wasm: wasm} do
      for source <- [wat, wasm] do
        {:ok, pid} = Wasmex.start_link(%{bytes: source})

        {:ok, [ptr, len]} = Wasmex.call_function(pid, :to_string, [])

        {:ok, memory} = Wasmex.memory(pid)
        {:ok, store} = Wasmex.store(pid)
        html = Wasmex.Memory.read_binary(store, memory, ptr, len)

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
    end

    test "can jump to 3rd step", %{wat: _wat, wasm: _wasm} do
      wat = Orb.to_wat(MultiStepForm)

      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Jump to step 3
      {:ok, []} = Wasmex.call_function(pid, :jump_to_step, [3])

      # Get HTML
      {:ok, [ptr, len]} = Wasmex.call_function(pid, :to_string, [])
      html = Wasmex.Memory.read_binary(store, memory, ptr, len)

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
      use SilverOrb.StringBuilder

      defwp daytime?(hour: I32), I32 do
        hour >= 6 &&& hour <= 19
      end

      defw render(hour: I32), StringBuilder do
        StringBuilder.build! do
          "<h1>"

          if daytime?(hour) do
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
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      get_html = fn ->
        {:ok, [ptr, len]} = Wasmex.call_function(pid, :text_html, [])
        Wasmex.Memory.read_binary(store, memory, ptr, len)
      end

      assert get_html.() ==
               ~S"""
               <!doctype html>
               <meta charset="utf-8">
               <h1>Hello 🌞 sunny world</h1>
               """

      {:ok, []} = Wasmex.call_function(pid, :set_hour_of_day, [2])

      assert get_html.() ==
               ~S"""
               <!doctype html>
               <meta charset="utf-8">
               <h1>Hello 🌛 moonlit world</h1>
               """

      # Test multiple calls to verify stability
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

  # Helper function to read strings
  defp call_reading_string(pid, store, memory, function, args \\ []) do
    {:ok, [ptr, len]} = Wasmex.call_function(pid, function, args)
    Wasmex.Memory.read_binary(store, memory, ptr, len)
  end

  describe "SetCookie" do
    @describetag :skip
    test "wasm size" do
      wat = Orb.to_wat(SetCookie)
      # Just check that the WAT contains expected functions
      assert wat =~ "set_cookie_name"
      assert wat =~ "set_cookie_value"
    end

    test "name and value" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory for strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])

      # Write strings to memory
      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])

      # Read result
      assert call_reading_string(pid, store, memory, :to_string) == "foo=value"
    end

    test "domain" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory and write strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])
      {:ok, [domain_ptr]} = Wasmex.call_function(pid, :alloc, [16])

      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, domain_ptr, "foo.example.com" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_domain, [domain_ptr])

      assert call_reading_string(pid, store, memory, :to_string) ==
               "foo=value; Domain=foo.example.com"
    end

    test "HttpOnly" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory and write strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])

      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_http_only, [])

      assert call_reading_string(pid, store, memory, :to_string) == "foo=value; HttpOnly"
    end

    test "HttpOnly Secure" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory and write strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])

      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_http_only, [])
      {:ok, []} = Wasmex.call_function(pid, :set_secure, [])

      assert call_reading_string(pid, store, memory, :to_string) == "foo=value; Secure; HttpOnly"
    end

    test "Domain HttpOnly Secure" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory and write strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])
      {:ok, [domain_ptr]} = Wasmex.call_function(pid, :alloc, [16])

      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, domain_ptr, "foo.example.com" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_domain, [domain_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_http_only, [])
      {:ok, []} = Wasmex.call_function(pid, :set_secure, [])

      assert call_reading_string(pid, store, memory, :to_string) ==
               "foo=value; Domain=foo.example.com; Secure; HttpOnly"
    end

    test "Domain Path HttpOnly Secure" do
      # Setup
      wat = SetCookie.to_wat()
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, memory} = Wasmex.memory(pid)
      {:ok, store} = Wasmex.store(pid)

      # Allocate memory and write strings
      {:ok, [name_ptr]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [value_ptr]} = Wasmex.call_function(pid, :alloc, [6])
      {:ok, [domain_ptr]} = Wasmex.call_function(pid, :alloc, [16])
      {:ok, [path_ptr]} = Wasmex.call_function(pid, :alloc, [2])

      Wasmex.Memory.write_binary(store, memory, name_ptr, "foo" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, value_ptr, "value" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, domain_ptr, "foo.example.com" <> <<0>>)
      Wasmex.Memory.write_binary(store, memory, path_ptr, "/" <> <<0>>)

      # Set values
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_name, [name_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_cookie_value, [value_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_domain, [domain_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_path, [path_ptr])
      {:ok, []} = Wasmex.call_function(pid, :set_http_only, [])
      {:ok, []} = Wasmex.call_function(pid, :set_secure, [])

      assert call_reading_string(pid, store, memory, :to_string) ==
               "foo=value; Domain=foo.example.com; Path=/; Secure; HttpOnly"
    end
  end
end
