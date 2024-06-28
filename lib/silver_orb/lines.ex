defmodule SilverOrb.Lines do
  defmacro alloc(name, opts) do
    quote do
      with do
        require SilverOrb.Arena

        opts = unquote(opts)
        _export_write = Keyword.get(opts, :export_write)
        SilverOrb.Arena.def(unquote(name), unquote(opts))
        # SilverOrb.Arena.def(unquote(name), unquote(Keyword.take(opts, [:align])))
      end
    end
  end
end
