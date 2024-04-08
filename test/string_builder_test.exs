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

  defw(to_string(), StringBuilder, do: to_html())

  defw to_html(), StringBuilder do
    build! do
      # "15 in hex is: "
      # append!(hex_upper: 15)

      build_step(1)
      build_step(2)
      build_step(3)
      build_step(4)
      build_step(5)
    end
  end

  defwp build_step(step: I32), StringBuilder, current_step?: I32 do
    current_step? = step === Orb.Instruction.global_get(:i32, :step)

    build! do
      ~S[<div class="w-4 h-4 text-center ]

      if current_step? do
        ~S[bg-blue-600 text-white]
      else
        ~S[text-black]
      end

      ~S[">]
      append!(decimal_u32: step)
      ~S[</div>\n]
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

  defw set_cookie_name(new_value: I32.UnsafePointer) do
    @name = new_value
  end

  defw set_cookie_value(new_value: I32.UnsafePointer) do
    @value = new_value
  end

  defw set_domain(new_value: I32.UnsafePointer) do
    @domain = new_value
  end

  defw set_path(new_path: I32.UnsafePointer) do
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
      instance = Instance.run(wat)

      assert to_string(instance) ==
               ~S"""
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

      assert to_string(instance) ==
               ~S"""
               <div class="w-4 h-4 text-center text-black">1</div>
               <div class="w-4 h-4 text-center text-black">2</div>
               <div class="w-4 h-4 text-center bg-blue-600 text-white">3</div>
               <div class="w-4 h-4 text-center text-black">4</div>
               <div class="w-4 h-4 text-center text-black">5</div>
               """
    end
  end

  describe "SetCookie" do
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
