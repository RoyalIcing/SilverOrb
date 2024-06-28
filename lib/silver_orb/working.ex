defmodule SilverOrb.Working do
  defmodule DSL do
    require Orb.DefwDSL

    defmacro string(name, opts) do
      quote do
        require SilverOrb.Arena
        require Orb.DefwDSL

        # SilverOrb.Arena.def(unquote(name), Keyword.take(unquote(opts), [:pages]))
        SilverOrb.Arena.def unquote(name), unquote(opts) do
        end
      end
    end

    defmacro lines(name, opts) do
      quote do
        require Orb
        require Orb.DefwDSL
        require SilverOrb.Arena

        module_name = Module.concat(__MODULE__, unquote(name))

        line_count_global_name =
          String.to_atom("#{Macro.inspect_atom(:literal, module_name)}.line_count")

        # Global.new_mut(I32, line_count_global_name, 0)
        # |> global()

        Orb.global(
          do: [
            {line_count_global_name, 0}
          ]
        )

        # SilverOrb.Arena.def(unquote(name), Keyword.take(unquote(opts), [:pages]))
        SilverOrb.Arena.def unquote(name), unquote(opts) do
          # Orb.DefwDSL.defw append(_line) do
          # end

          # Orb.DefwDSL.defw sort() do
          # end

          def append(_line) do
          end

          def sort() do
          end
        end
      end
    end
  end
end
