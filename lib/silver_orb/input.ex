defmodule SilverOrb.Input do
  defmodule DSL do
    require Orb.Control
    require Orb.I32
    require Orb
    require Orb.IfElse.DSL
    require Orb.DSL
    require Orb.DefwDSL

    defmacro string(name, opts) do
      quote do
        require SilverOrb.Arena
        require Orb.DefwDSL

        # SilverOrb.Arena.def(unquote(name), Keyword.take(unquote(opts), [:pages]))
        SilverOrb.Arena.def unquote(name), unquote(opts) do
        end

        Orb.DefwDSL.defw unquote(opts[:export])(), Orb.I32 do
          43
        end
      end
    end

    defmacro lines(name, opts) do
      quote do
        require SilverOrb.Arena
        require Orb.DefwDSL

        # SilverOrb.Arena.def(unquote(name), Keyword.take(unquote(opts), [:pages]))
        SilverOrb.Arena.def unquote(name), unquote(opts) do
          def lines() do
            %{push_type: __MODULE__}
          end

          def valid?(_) do
            Orb.DSL.i32(0)
          end

          def value(_) do
            Orb.DSL.i32(0)
          end

          def next(_) do
            Orb.snippet do
              Orb.Control.block Next, Orb.I32 do
                # Orb.DSL.i32(0)
                loop char <- Orb.Instruction.global_get(I32, line_offset_global) do
                  if(char === ?\n) do
                    Next.break(char + 1)
                  end
                end

                # Input.Chars.reduce_while Orb.Instruction.global_get(I32, line_offset_global) do
                #   ?\n ->
                #     {:halt, char + 1}

                #   _ ->
                #     {:cont, char + 1}
                # end
              end
            end
          end
        end

        Orb.DefwDSL.defw unquote(opts[:export])(), Orb.I32 do
          44
        end
      end
    end
  end
end
