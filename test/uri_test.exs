defmodule URITest do
  use WasmexCase, async: true

  @moduletag wat: Orb.to_wat(SilverOrb.URI)

  describe "parse" do
    alias SilverOrb.URI.URIParseResult, as: Result

    setup %{
      input: input,
      call_function: call_function,
      write_binary: write_binary,
      read_binary: read_binary
    } do
      import Bitwise

      write_binary.(0x100, input)

      assert {:ok, values} = call_function.("parse", [0x100, byte_size(input)])
      result = Result.from_values(values)
      expected_result = URI.parse(input)

      case expected_result.scheme do
        nil ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:scheme]))

        scheme when is_binary(scheme) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:scheme]))
      end

      case expected_result.userinfo do
        nil ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:userinfo]))

        userinfo when is_binary(userinfo) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:userinfo]))
      end

      case expected_result.host do
        host when host in [nil, ""] ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:host]))

        host when is_binary(host) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:host]))
      end

      case expected_result.path do
        nil ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:path]))

        path when is_binary(path) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:path]))
      end

      case expected_result.query do
        nil ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:query]))

        query when is_binary(query) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:query]))
      end

      case expected_result.fragment do
        nil ->
          assert 0 === band(result.flags, SilverOrb.URI.parse_flags([:fragment]))

        fragment when is_binary(fragment) ->
          assert 0 !== band(result.flags, SilverOrb.URI.parse_flags([:fragment]))
      end

      assert (expected_result.scheme || "") ===
               read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))

      assert (expected_result.userinfo || "") ===
               read_binary.(elem(result.userinfo, 0), elem(result.userinfo, 1))

      assert (expected_result.host || "") ===
               read_binary.(elem(result.host, 0), elem(result.host, 1))

      # assert to_string(expected_result.port) ===
      #          read_binary.(elem(result.port, 0), elem(result.port, 1))

      assert (expected_result.path || "") ===
               read_binary.(elem(result.path, 0), elem(result.path, 1))

      assert (expected_result.query || "") ===
               read_binary.(elem(result.query, 0), elem(result.query, 1))

      assert (expected_result.fragment || "") ===
               read_binary.(elem(result.fragment, 0), elem(result.fragment, 1))

      %{result: result, expected_result: expected_result}
    end

    @tag input: "mailto:"
    test "parse mailto:", %{result: result} do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme])
      assert result.scheme == {0x100, 6}
    end

    @tag input: "http:"
    test "parse http:", %{result: result} do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme])
      assert result.scheme == {0x100, 4}
    end

    @tag input: "tel:+1-816-555-1212"
    test "parse tel:+1-816-555-1212", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme, :path])
      assert result.scheme == {0x100, 3}
      assert result.path == {0x104, 15}

      assert "+1-816-555-1212" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "file:///home/user/file.txt"
    test "parse file:///home/user/file.txt", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme, :path])
      assert result.scheme == {0x100, 4}
      assert result.path == {0x107, 19}

      assert "file" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "/home/user/file.txt" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "ftp://ftp.is.co.za/rfc/rfc1808.txt"
    test "parse ftp://ftp.is.co.za/rfc/rfc1808.txt", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme, :host, :path])
      assert result.scheme == {0x100, 3}
      assert result.host == {0x106, 12}
      assert result.path == {0x112, 16}

      assert "ftp" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "ftp.is.co.za" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "/rfc/rfc1808.txt" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "news:comp.infosystems.www.servers.unix"
    test "parse news:comp.infosystems.www.servers.unix", %{
      result: result,
      read_binary: read_binary
    } do
      assert result.flags == SilverOrb.URI.parse_flags([:scheme, :path])
      assert {0x100, 4} = result.scheme
      assert {_, 0} = result.host
      assert {0x105, 33} = result.path

      assert "news" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))

      assert "comp.infosystems.www.servers.unix" =
               read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "https://user@example.com"
    test "https://user@example.com", %{result: result, read_binary: read_binary} do
      assert "user" = read_binary.(elem(result.userinfo, 0), elem(result.userinfo, 1))
      assert "" = read_binary.(elem(result.port, 0), elem(result.port, 1))
    end

    @tag input: "https://user@example.com:1234/?q=dogs&sort=cutest#beagles"
    test "https://user@example.com:1234/?q=dogs&sort=cutest#beagles", %{
      result: result,
      read_binary: read_binary
    } do
      assert result.flags ==
               SilverOrb.URI.parse_flags([
                 :scheme,
                 :userinfo,
                 :host,
                 :path,
                 :port,
                 :query,
                 :fragment
               ])

      assert "https" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "user" = read_binary.(elem(result.userinfo, 0), elem(result.userinfo, 1))
      assert "example.com" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "1234" = read_binary.(elem(result.port, 0), elem(result.port, 1))
      assert "q=dogs&sort=cutest" = read_binary.(elem(result.query, 0), elem(result.query, 1))
      assert "beagles" = read_binary.(elem(result.fragment, 0), elem(result.fragment, 1))
    end

    @tag input: "http://example.com:"
    test "http://example.com:", %{result: result, read_binary: read_binary} do
      assert "" = read_binary.(elem(result.port, 0), elem(result.port, 1))
    end

    @tag input: "http://example.com:65535/"
    test "http://example.com:65535/", %{result: result, read_binary: read_binary} do
      assert "65535" = read_binary.(elem(result.port, 0), elem(result.port, 1))
    end

    @tag input: "example.com/path"
    test "example.com/path", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:path])
      assert result.path == {0x100, 16}

      assert "" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "example.com/path" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "/example.com/path"
    test "/example.com/path", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:path])
      assert result.path == {0x100, 17}

      assert "" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "/example.com/path" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "//example.com/path"
    test "//example.com/path", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:host, :path])
      assert result.host == {0x102, 11}
      assert result.path == {0x10D, 5}

      assert "" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "example.com" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "/path" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "///example.com/path"
    test "///example.com/path", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:path])
      assert result.path == {0x102, 17}

      assert "" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "/example.com/path" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "////example.com/path"
    test "////example.com/path", %{result: result, read_binary: read_binary} do
      assert result.flags == SilverOrb.URI.parse_flags([:path])
      assert result.path == {0x102, 18}

      assert "" = read_binary.(elem(result.scheme, 0), elem(result.scheme, 1))
      assert "" = read_binary.(elem(result.host, 0), elem(result.host, 1))
      assert "//example.com/path" = read_binary.(elem(result.path, 0), elem(result.path, 1))
    end

    @tag input: "http://example.com"
    test "http://example.com", do: :ok

    @tag input: "https://"
    test "https://", do: :ok

    @tag input: "http://example.com//"
    test "http://example.com//", do: :ok

    @tag input: "http:///path"
    test "http:///path", do: :ok

    @tag input: "file:/path/to/file"
    test "file:/path/to/file", do: :ok

    @tag input: "http://example.com/path?"
    test "http://example.com/path?", do: :ok

    @tag input: "http://example.com/path#"
    test "http://example.com/path#", do: :ok

    @tag input: "http://example.com/?q=a+b"
    test "http://example.com/?q=a+b", do: :ok

    @tag input: "http://example.com/?q=dogs#beagles"
    test "http://example.com/?q=dogs#beagles", do: :ok

    @tag input: "urn:isbn:0451450523"
    test "urn:isbn:0451450523", do: :ok

    # @tag input: "http://user:pass@example.com"
    # test "http://user:pass@example.com", do: :ok
  end

  describe "parse_query_pair" do
    test "q=dogs&sort=cutest", %{
      call_function: call_function,
      write_binary: write_binary,
      read_binary: read_binary
    } do
      input = "q=dogs&sort=cutest"
      expected_result = URI.decode_query(input)

      write_binary.(0x100, input)

      assert {:ok, values} = call_function.("parse_query_pair", [0x100, byte_size(input)])
      result = SilverOrb.URI.ParseQueryPairResult.from_values(values)

      assert result.key == {0x100, 1}
      assert result.value == {0x102, 4}
      assert result.rest == {0x107, 11}

      assert "q" = read_binary.(elem(result.key, 0), elem(result.key, 1))
      assert "dogs" = read_binary.(elem(result.value, 0), elem(result.value, 1))
      assert "sort=cutest" = read_binary.(elem(result.rest, 0), elem(result.rest, 1))

      assert {:ok, values} = call_function.("parse_query_pair", Tuple.to_list(result.rest))
      result = SilverOrb.URI.ParseQueryPairResult.from_values(values)

      assert result.key == {0x107, 4}
      assert result.value == {0x10C, 6}
      assert result.rest == {0x112, 0}

      assert "sort" = read_binary.(elem(result.key, 0), elem(result.key, 1))
      assert "cutest" = read_binary.(elem(result.value, 0), elem(result.value, 1))
      assert "" = read_binary.(elem(result.rest, 0), elem(result.rest, 1))
    end
  end
end
