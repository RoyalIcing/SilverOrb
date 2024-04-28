defmodule SilverOrb.Sort do
  # https://stackoverflow.com/a/17271911
  def bubble_sort(opts) do
    use Orb

    count = Keyword.fetch!(opts, :count)
    read_at = Keyword.fetch!(opts, :read_at)
    swap_at_with_next = Keyword.fetch!(opts, :swap_at_with_next)
    calc_gt = Keyword.fetch!(opts, :calc_gt)

    Orb.snippet Orb.Numeric, i: I32, j: I32 do
      # local i: i32(0) do
      Orb.InstructionSequence.new(
        nil,
        [
          i = 0,
          loop BubbleSort do
            Orb.InstructionSequence.new(nil, [
              j = 0,
              loop BubbleSortInner do
                if calc_gt.(read_at.(j), read_at.(j + 1)) do
                  swap_at_with_next.(j)
                end

                j = j + 1

                if j < I32.sub(count, 1) - i do
                  BubbleSortInner.continue()
                end
              end
            ])

            i = i + 1

            if i < I32.sub(count, 1) do
              BubbleSort.continue()
            end

            # end
          end
        ],
        locals: [i: I32, j: I32, dup_i32: I32]
      )
    end
  end
end
