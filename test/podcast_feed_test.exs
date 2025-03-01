defmodule PodcastFeedTest do
  use ExUnit.Case, async: true

  defp wasmex_imports(opts) do
    %{
      datasource: %{
        get_episodes_count:
          {:fn, [], [:i32],
           fn _context ->
             Keyword.fetch!(opts, :episodes_count)
           end},
        write_episode_id:
          {:fn, [:i32, :i32], [:i32],
           fn context, id, write_at ->
             s = "#{id + 1}"

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end},
        get_episode_pub_date_utc:
          {:fn, [:i32], [:i64],
           fn _context, [_id] ->
             0
           end},
        get_episode_duration_seconds:
          {:fn, [:i32], [:i32],
           fn _context, [_id] ->
             0
           end},
        write_episode_title:
          {:fn, [:i32, :i32], [:i32],
           fn context, id, write_at ->
             s = "Episode #{id + 1}"

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end},
        write_episode_description:
          {:fn, [:i32, :i32], [:i32],
           fn context, id, write_at ->
             s = "Description for #{id + 1}"

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end},
        write_episode_link_url:
          {:fn, [:i32, :i32], [:i32],
           fn context, _id, write_at ->
             s = ""

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end},
        write_episode_mp3_url:
          {:fn, [:i32, :i32], [:i32],
           fn context, _id, write_at ->
             s = ""

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end},
        get_episode_mp3_byte_count:
          {:fn, [:i32], [:i32],
           fn _context, _id ->
             0
           end},
        write_episode_content_html:
          {:fn, [:i32, :i32], [:i32],
           fn context, _id, write_at ->
             s = ""

             # Write string with null terminator to memory
             :ok =
               Wasmex.Memory.write_binary(context.caller, context.memory, write_at, s <> <<0>>)

             # Return length without null terminator
             byte_size(s)
           end}
      }
    }
  end

  # Define setup
  setup context do
    wat = Orb.to_wat(SilverOrb.PodcastFeed)
    imports = wasmex_imports(episodes_count: context[:episodes_count] || 2)
    {:ok, pid} = Wasmex.start_link(%{bytes: wat, imports: imports})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)
    write_binary = &Wasmex.Memory.write_binary(store, memory, &1, &2)

    %{
      pid: pid,
      store: store,
      memory: memory,
      call_function: call_function,
      read_binary: read_binary,
      write_binary: write_binary
    }
  end

  test "podcast xml feed rendering", %{
    store: store,
    pid: pid,
    write_binary: write_binary,
    call_function: call_function,
    read_binary: read_binary
  } do
    # Allocate memory at fixed locations for strings
    title_ptr = 0x400
    title_size = byte_size("SOME TITLE")
    desc_ptr = 0x500
    desc_size = byte_size("SOME DESCRIPTION")
    author_ptr = 0x600
    author_size = byte_size("Hall & Oates")

    # Write strings to memory
    write_binary.(title_ptr, "SOME TITLE" <> <<0>>)
    write_binary.(desc_ptr, "SOME DESCRIPTION" <> <<0>>)
    write_binary.(author_ptr, "Hall & Oates" <> <<0>>)

    {:ok, instance} = Wasmex.instance(pid)

    Wasmex.Instance.set_global_value(
      store,
      instance,
      "title",
      Orb.Memory.Slice.from(title_ptr, title_size)
    )

    Wasmex.Instance.set_global_value(
      store,
      instance,
      "description",
      Orb.Memory.Slice.from(desc_ptr, desc_size)
    )

    Wasmex.Instance.set_global_value(
      store,
      instance,
      "author",
      Orb.Memory.Slice.from(author_ptr, author_size)
    )

    # Generate XML
    {:ok, [ptr, len]} = call_function.(:text_xml, [])
    text_xml = read_binary.(ptr, len)

    assert text_xml =~ ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           """

    root = xml_parse(text_xml)

    assert "SOME DESCRIPTION" = xml_text_content(root, "/rss/channel/description[1]")
    assert "Hall & Oates" = xml_text_content(root, "/rss/channel/itunes:author[1]")

    [item1, item2] = xml_xpath(root, "//item")
    assert "1" = xml_text_content(item1, "//guid[@isPermaLink='false'][1]")
    assert "2" = xml_text_content(item2, "//guid[@isPermaLink='false'][1]")
    assert "Episode 1" = xml_text_content(item1, "//title[1]")
    assert "Episode 2" = xml_text_content(item2, "//title[1]")
    assert "Episode 1" = xml_text_content(item1, "//itunes:title[1]")
    assert "Episode 2" = xml_text_content(item2, "//itunes:title[1]")
    assert "Description for 1" = xml_text_content(item1, "//description[1]")
    assert "Description for 2" = xml_text_content(item2, "//description[1]")
  end

  @tag episodes_count: 12_000
  test "12,000 episodes", %{
    pid: pid,
    call_function: call_function,
    read_binary: read_binary
  } do
    # Generate XML
    {:ok, [ptr, len]} = call_function.(:text_xml, [])
    text_xml = read_binary.(ptr, len)

    assert text_xml =~ ~S"""
           <?xml version="1.0" encoding="UTF-8"?>
           """

    root = xml_parse(text_xml)
    items = xml_xpath(root, "//item")
    assert 12_000 = length(items)
  end

  defp xml_parse(xml) do
    {root, []} = xml |> String.to_charlist() |> :xmerl_scan.string()
    root
  end

  defp xml_xpath(el, xpath) when is_binary(xpath) do
    :xmerl_xs.select(String.to_charlist(xpath), el)
  end

  defp xml_text_content(el, xpath) when is_binary(xpath) do
    xml_xpath(el, xpath) |> hd() |> xml_text_content()
  end

  defp xml_text_content(el) do
    :xmerl_lib.foldxml(&do_xml_text_content/2, [], el)
    |> :lists.reverse()
    |> List.to_string()
  end

  require Record
  Record.defrecord(:xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl"))

  defp do_xml_text_content(node, acc) when Record.is_record(node, :xmlText) do
    [:xmerl_lib.flatten_text(xmlText(node, :value)) | acc]
  end

  defp do_xml_text_content(_, acc), do: acc

  test "output optimized wasm" do
    path_wasm = Path.join(__DIR__, "podcast_feed_xml.wasm")
    path_wat = Path.join(__DIR__, "podcast_feed_xml.wat")
    path_opt_wasm = Path.join(__DIR__, "podcast_feed_xml_OPT.wasm")
    path_opt_wat = Path.join(__DIR__, "podcast_feed_xml_OPT.wat")

    # Get WAT and convert to WASM
    wat = Orb.to_wat(SilverOrb.PodcastFeed)
    File.write!(path_wat, wat)

    # Convert WAT to WASM using wat2wasm
    System.cmd("wat2wasm", [path_wat, "-o", path_wasm])
    System.cmd("wasm-opt", ["--enable-multivalue", path_wasm, "-o", path_opt_wasm, "-O"])

    %{size: size} = File.stat!(path_wasm)
    assert size > 0

    %{size: size} = File.stat!(path_opt_wasm)
    assert size > 0

    {wat_text, 0} = System.cmd("wasm2wat", [path_wasm])
    File.write!(path_wat, wat_text)
    {opt_wat, 0} = System.cmd("wasm2wat", [path_opt_wasm])
    File.write!(path_opt_wat, opt_wat)
  end
end
