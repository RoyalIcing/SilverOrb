defmodule SilverOrb.HTML do
  use Orb

  # Approach 1: memory pages for working:
  # Accept 1 page of memory for input.
  # 1 page of memory for output.
  # Returns actual byte count written. If written less, does memmove from remaining to start?
  #
  # Approach 2: stack for working:
  # Accept i64 param as input.
  # Pushes i32 len and i64x6 result as output.
  #
  # Approach 3: stack for input, memory for output:
  # Accept i64 param as input, and ptr to memory to write to.
  # Returns byte count written.

  # defw approach2(chars: I64), {I32, I64, I64, I64, I64, I64, I64} do
  #   c0 = chars[u8: 0]
  #   if c0 === ?< do
  #     ?& + ?l + ?t + ?;
  #   else
  #     c0 # But what about next char?
  #   end
  # end

  # defw approach3(chars: I64, write_ptr: I32.U8.UnsafePointer), I32, write_count: I32 do
  #   if chars[u8_at: 0] === ?< do
  #     write_ptr[at!: 0] = ?&
  #     write_ptr[at!: 1] = ?l
  #     write_ptr[at!: 2] = ?t
  #     write_ptr[at!: 3] = ?;
  #     write_ptr = write_ptr + 4
  #     write_count = 4
  #   else
  #     chars
  #   end
  # end

  defmacrop cond2(result_type, do: block) do
    line = __CALLER__.line
    block_name = "cond_#{line}"

    instructions =
      for {:->, _, [[condition], result]} <- block do
        quote do
          case unquote(condition) do
            true ->
              unquote(result)

            condition ->
              Orb.IfElse.new(
                condition,
                Orb.InstructionSequence.new([
                  unquote(result),
                  Orb.Control.break(unquote(block_name))
                ])
              )
              # TODO: need to add branch_type to Orb?
              |> Map.put(:push_type, nil)

              # Orb.InstructionSequence.new([
              #   unquote(result),
              #   Orb.Control.break(unquote(block_name), if: condition),
              #   Orb.Stack.drop(%Orb.Nop{push_type: Orb.I32})
              # ])
          end
        end
      end

    quote do
      with do
        require Orb.Control

        instructions = unquote(instructions)

        Orb.Control.block unquote(block_name), unquote(result_type) do
          Orb.InstructionSequence.new(instructions)
        end
      end
    end
  end

  defw escape_char_count(char: I32.U8), I32 do
    cond2 I32 do
      char === ?< -> i32(4)
      char === ?> -> i32(4)
      char === ?& -> i32(5)
      char === ?" -> i32(6)
      char === ?' -> i32(5)
      true -> i32(1)
    end

    # case char do
    #   ?< -> 4
    #   ?> -> 4
    #   ?& -> 5
    #   ?" -> 6
    #   ?' -> 5
    #   _ -> char
    # end
  end

  defw escape_char(char: I32.U8, write_ptr: I32.U8.UnsafePointer), I32, write_count: I32 do
    cond do
      char === ?< ->
        # write_ptr[write_utf8!: "&amp;"]
        # write_ptr[:utf8!] = "&amp;"
        write_ptr[at!: 0] = ?&
        write_ptr[at!: 1] = ?l
        write_ptr[at!: 2] = ?t
        write_ptr[at!: 3] = ?;
        4

      char === ?> ->
        write_ptr[at!: 0] = ?&
        write_ptr[at!: 1] = ?g
        write_ptr[at!: 2] = ?t
        write_ptr[at!: 3] = ?;
        4

      char === ?& ->
        write_ptr[at!: 0] = ?&
        write_ptr[at!: 1] = ?a
        write_ptr[at!: 2] = ?m
        write_ptr[at!: 3] = ?p
        write_ptr[at!: 4] = ?;
        5

      char === ?" ->
        write_ptr[at!: 0] = ?&
        write_ptr[at!: 1] = ?q
        write_ptr[at!: 2] = ?u
        write_ptr[at!: 3] = ?o
        write_ptr[at!: 4] = ?t
        write_ptr[at!: 5] = ?;
        6

      char === ?' ->
        write_ptr[at!: 0] = ?&
        write_ptr[at!: 1] = ?#
        write_ptr[at!: 2] = ?3
        write_ptr[at!: 3] = ?9
        write_ptr[at!: 4] = ?;
        5

      true ->
        write_ptr[at!: 0] = char
        1
    end
  end

  # A mapper can be inlined trivially.
  # defwmap escape_char(I32.U8) :: Str do
  #   ?< -> "&lt;"
  #   ?> -> "&gt;"
  #   ?& -> "&amp;"
  #   ?" -> "&quot;"
  #   ?' -> "&#39;"
  #   char -> char
  # end

  defmodule EscapeCharMapper do
    # TODO: read https://lemire.me/blog/2024/10/14/table-lookups-are-efficient/
    # use SilverOrb.Mapper, input: I32.U8, output: Str do
    #   ?< -> "&lt;"
    #   ?> -> "&gt;"
    #   ?& -> "&amp;"
    #   ?" -> "&quot;"
    #   ?' -> "&#39;"
    #   char -> char
    # end
  end

  #   defw escape(
  #          input_ptr: I32.UnsafePointer,
  #          input_len: I32,
  #          output_ptr: I32.UnsafePointer,
  #          output_max_len: I32
  #        ),
  #        I32,
  #        len: I32,
  #        output_so_far: I32 do
  #     loop char <- Memory.slice(input_ptr, input_len).bytes do
  #       # len = escape_char(:byte_size, char)
  # 
  #       # This gets inlined
  #       len = EscapeCharMapper.output_byte_size(char)
  # 
  #       if output_so_far + len > output_max_len do
  #         return(output_so_far)
  #       end
  # 
  #       # return output_so_far when output_so_far + len > output_max_len
  # 
  #       # Mapper.write!(escape_char(:mapper), char, output_ptr)
  #       # This gets inlined, with manual outputting char-by-char for strings.
  #       # e.g. & then a then m then p then ;
  #       EscapeCharMapper.output!(char, output_ptr)
  # 
  #       output_so_far = output_so_far + len
  #     end
  # 
  #     output_so_far
  #   end

  # defw escape(
  #        input_ptr: I32.UnsafePointer,
  #        input_len: I32,
  #        output_ptr: I32.UnsafePointer,
  #        output_max_len: I32
  #      ),
  #      %{type: I32, read: output_so_far, add: did_output_by, return: return} do
  #   loop char <- Memory.at(input_ptr, input_len).bytes do
  #     # len = escape_char(:byte_size, char)

  #     # This gets inlined
  #     len = EscapeCharMapper.output_byte_size(char)

  #     if output_so_far + len > output_max_len do
  #       return
  #     end

  #     # Mapper.write!(escape_char(:mapper), char, output_ptr)
  #     # This gets inlined, with manual outputting char-by-char for strings.
  #     # e.g. & then a then m then p then ;
  #     EscapeCharMapper.output!(char, output_ptr)

  #     did_output_by.(len)
  #   end
  # end
end
