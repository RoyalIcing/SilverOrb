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
        1
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

defmodule StringBuilderTest do
  use ExUnit.Case, async: true
  alias OrbWasmtime.Instance

  describe "MultiStepForm" do
    test "highlights first step" do
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
end
