defmodule GitIgnoreParser do
  use Orb

  import SilverOrb
  require SilverOrb.Lines

  input do
    lines(GitIgnoreContent, export: :get_gitignore_range, pages: 1)
    string(Path, export: :get_path_range, pages: 1)
  end

  working do
    # lines(GitIgnoreLineOffsetsSorted, pages: 1)
    slices(GitIgnoreLineOffsetsSorted, pages: 1)
  end

  defw input_ready(), line_count: I32 do
    loop line_slice <- GitIgnoreContent.line_slices() do
      # GitIgnoreLineOffsetsSorted.push(line.slice)
      GitIgnoreLineOffsetsSorted.push(line_slice)
    end

    # GitIgnoreContent.lines line do
    #   # GitIgnoreLineOffsetsSorted.push(line.slice)
    #   GitIgnoreLineOffsetsSorted.push(line)
    # end

    GitIgnoreLineOffsetsSorted.sort()
  end

  ###############

  # defw input_ready(), line_count: I32 do
  #   GitIgnoreLineOffsetsSorted.insert(GitIgnoreContent.lines(:slice), fn line -> line.slice end)

  #   GitIgnoreLineOffsetsSorted.sort()
  # end

  # defw input_ready(), line_count: I32 do
  #   loop line <- GitIgnoreContent.lines() do
  #     GitIgnoreLineOffsetsSorted.append(line.slice)
  #     line_count = line_count + 1
  #   end

  #   GitIgnoreLineOffsetsSorted.sort(line_count)
  # end

  # defw input_ready(), line_count: I32 do
  #   loop line <- GitIgnoreContent.lines(), store_count: mut!(line_count) do
  #     GitIgnoreLineOffsetsSorted.append(line.slice)
  #   end

  #   GitIgnoreLineOffsetsSorted.sort(line_count)
  # end

  # defw input_ready(), line_count: I32 do
  #   loop line <- GitIgnoreContent.lines() do
  #     GitIgnoreLineOffsetsSorted.append(line.slice)
  #   end
  #   |> Loop.count_into(mut!(line_count))

  #   GitIgnoreLineOffsetsSorted.sort(line_count)
  # end

  # defw input_ready() do
  #   loop line <- GitIgnoreContent.lines() do
  #     GitIgnoreLineOffsetsSorted.append(line.slice)
  #   end
  #   |> loop(line_count <- I32.range())

  #   GitIgnoreLineOffsetsSorted.sort(line_count)
  # end

  # defw input_ready(), line_count: I32 do
  #   loop line <- GitIgnoreContent.lines() do
  #     GitIgnoreLineOffsetsSorted.append(line.slice)
  #   end
  #   |> increment(mut!(line_count))

  #   GitIgnoreLineOffsetsSorted.sort(line_count)
  # end

  # defw input_ready() do
  #   loop line <- input.git_ignore do
  #     Line.append(working.git_ignore_line_offsets_sorted, line.slice)
  #   end
  #   |> Loop.count()
  #   |> Sort.bubble(GitIgnoreLineOffsetsSorted.sort_options())
  # end

  # SilverOrb.Lines.defp(GitIgnoreLineOffsetsSorted, pages: 1)
  #
  #   SilverOrb.Lines.def(GitIgnoreLineOffsetsSorted, pages: 1)

  #   SilverOrb.Lines.pages(1, GitIgnoreLineOffsetsSorted)

  # SilverOrb.Lines.def GitIgnoreContent, pages: 1, export_write: :write_gitignore do
  # loop line <- GitIgnoreContent.lines() do
  #   GitIgnoreLineOffsetsSorted.append(line.slice)
  # end
  # |> Loop.count()
  # |> Sort.bubble(GitIgnoreLineOffsetsSorted.sort_options())

  # GitIgnoreLineOffsetsSorted.sort()
  # end

  #   SilverOrb.Input.string(Path, export_write: :write_path, pages: 1)

  #   defw ignored?(), I32 do
  #     for line <- GitIgnoreLineOffsetsSorted.lines() do
  #       local order = evaluate_line(line, Path) do
  #         case order do
  #           # before
  #           -1 ->
  #             # continue
  #             nop()

  #           # after
  #           1 ->
  #             return(i32(0))

  #           # matches
  #           0 ->
  #             return(i32(1))
  #         end
  #       end
  #     end
  #   end

  #   defwp evaluate_line(line: SilverOrb.Input.Line) do
  #   end
end

defmodule GitIgnoreTest do
  use ExUnit.Case, async: true
  @moduletag timeout: 1000
  alias OrbWasmtime.Instance

  # test "wat" do
  #   assert "" = Orb.to_wat(GitIgnoreParser)
  # end

  test "exports" do
    inst = Instance.run(GitIgnoreParser)

    assert [
             {:memory, "memory"},
             {:func, "get_gitignore_range"},
             {:func, "get_path_range"}
           ] = OrbWasmtime.Instance.exports(inst)
  end
end
