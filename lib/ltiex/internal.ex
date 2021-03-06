defmodule Ltiex.Internal do
  @moduledoc false

  @exclude_params ["format", "realm", "oauth_signature"]

  @doc """
  Decode OAuth params from an Authorization header string

  ## Examples

      iex> Ltiex.Internal.oauth_header_params(~s(OAuth realm="", oauth_body_hash="something"))
      %{"oauth_body_hash" => "something", "realm" => ""}

      iex> Ltiex.Internal.oauth_header_params(~s(OAuth oauth_signature="ILd%3D", oauth_version="1.0"))
      %{"oauth_signature" => "ILd=", "oauth_version" => "1.0"}

      iex> Ltiex.Internal.oauth_header_params(~s(Header something))
      %{}

  """
  @spec oauth_header_params(binary) :: %{optional(binary()) => binary()}
  def oauth_header_params(header)

  def oauth_header_params("OAuth " <> header) do
    header
    |> String.replace(~r/\s?,\s?/, "&")
    |> String.replace(~s("), "")
    |> URI.decode_query()
  end

  def oauth_header_params(_), do: %{}

  @doc """
  Strip the query params from a uri.

  ## Examples

      iex> Ltiex.Internal.strip_uri_query("https://google.com?q=something&foo=bar")
      "https://google.com"

      iex> Ltiex.Internal.strip_uri_query("https://localhost:4000/api/lti/?q=something")
      "https://localhost:4000/api/lti/"

  """
  @spec strip_uri_query(binary() | URI.t()) :: binary()
  def strip_uri_query(uri) do
    uri
    |> URI.parse()
    |> Map.put(:query, nil)
    |> URI.to_string()
  end

  @doc """
  Encode the params map into a single string as per LTI encoding rules.

  Certain protected keys are filtered out like "oauth_signature", which is not
  used in the digest generation.

  ## Examples

      iex> Ltiex.Internal.encode_lti_form([{"foo","hello world!"}, {"bar", "test"}])
      "bar=test&foo=hello%20world%21"

      iex> Ltiex.Internal.encode_lti_form(%{"oauth_signature" => "IL+2=", "foo" => "bar+"})
      "foo=bar%2B"

      iex> Ltiex.Internal.encode_lti_form(%{"bad_param" => nil})
      "bad_param="

  """
  @spec encode_lti_form(%{optional(binary) => binary}) :: binary()
  def encode_lti_form(params) do
    params
    |> Enum.filter(&(!Enum.member?(@exclude_params, elem(&1, 0))))
    |> Enum.map(&encode_param/1)
    |> Enum.sort()
    |> Enum.join("&")
  end

  defp encode_param({key, value}) do
    encoded_value =
      value
      |> to_string()
      |> URI.encode_www_form()

    # Replace '+' characters with the actual percent encoding value: '%20'
    # This has to be done has Elixir's `URI.encode_www_form` encodes spaces as
    # '+', instead of the old percent encoded '%20' character.
    Regex.replace(~r/\+/, "#{key}=#{encoded_value}", "%20")
  end
end
