# lib/altar/translation/google_translate.ex
defmodule Altar.Translation.GoogleTranslate do
  @moduledoc """
  Google Translate API implementation
  """

  @base_url "https://translation.googleapis.com/language/translate/v2"

  def translate(text, source_lang, target_lang) do
    api_key = get_api_key()

    params = %{
      q: text,
      source: source_lang,
      target: target_lang,
      key: api_key
    }

    case HTTPoison.post(@base_url, Jason.encode!(params), headers()) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => %{"translations" => [%{"translatedText" => translated} | _]}}} ->
            {:ok, translated}

          _ ->
            {:error, "Invalid response format"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "API error: #{status_code} - #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Network error: #{reason}"}
    end
  end

  defp get_api_key do
    case Application.get_env(:altar, :google)[:translate_api_key] do
      {:system, env_var} -> System.get_env(env_var)
      api_key -> api_key
    end
  end

  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ]
  end
end
