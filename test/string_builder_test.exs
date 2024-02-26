defmodule MultiStepForm do
  # See: https://buildui.com/courses/framer-motion-recipes/multistep-wizard

  use Orb
  use SilverOrb.BumpAllocator
  use I32.String
  use SilverOrb.StringBuilder
  alias Orb.I32

  I32.export_global(:mutable, step_count: 4)

  global do
    @step 1
  end

  defw(get_current_step(), I32, do: @step)

  defwp change_step(step: I32) do
    @step =
      if step < 1 do
        1
      else
        if(step > @step_count, do: @step_count, else: step)
      end
  end

  defw(next_step(), do: change_step(@step + 1))
  defw(previous_step(), do: change_step(@step - 1))
  defw(jump_to_step(step: I32), do: change_step(step))

  defw(to_string(), I32.String, do: to_html())

  defw to_html(), I32.String do
    build! do
      build_step(1)
      build_step(2)
      build_step(3)
      build_step(4)
      build_step(5)
    end
  end

  defwp build_step(step: I32), I32.String, current_step?: I32 do
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

defmodule StringBuilderTest do
  use ExUnit.Case, async: true
  alias OrbWasmtime.{Instance, Wasm}

  describe "MultiStepForm" do
    test "works" do
      instance = Instance.run(MultiStepForm)

      assert to_string(instance) ==
               ~S"""
               <div class="w-4 h-4 text-center bg-blue-600 text-white">1</div>
               <div class="w-4 h-4 text-center text-black">2</div>
               <div class="w-4 h-4 text-center text-black">3</div>
               <div class="w-4 h-4 text-center text-black">4</div>
               <div class="w-4 h-4 text-center text-black">5</div>
               """
    end
  end
end
