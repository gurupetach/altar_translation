# lib/altar/speech/google_text_to_speech.ex
defmodule Altar.Speech.GoogleTextToSpeech do
  @moduledoc """
  Google Cloud Text-to-Speech API implementation
  """

  require Logger

  @api_endpoint "https://texttospeech.googleapis.com/v1/text:synthesize"

  def synthesize_speech(text, language_code, opts \\ []) do
    voice_config = get_voice_config(language_code)

    request_body = %{
      input: %{
        text: text
      },
      voice: voice_config,
      audioConfig: %{
        audioEncoding: "MP3",
        speakingRate: opts[:speaking_rate] || 1.0,
        pitch: opts[:pitch] || 0.0
      }
    }

    credentials = load_credentials()

    headers = [
      {"Authorization", "Bearer #{get_access_token(credentials)}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(@api_endpoint, Jason.encode!(request_body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"audioContent" => audio_content}} ->
            audio_data = Base.decode64!(audio_content)
            {:ok, %{audio_data: audio_data, format: "mp3"}}

          _ ->
            {:error, "Invalid response format"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("TTS API error: #{status_code} - #{body}")
        {:error, "API error: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Network error: #{reason}")
        {:error, "Network error: #{reason}"}
    end
  end

  defp get_voice_config(language_code) do
    voice_settings = Application.get_env(:altar, :google)[:voice_settings]

    case Map.get(voice_settings, language_code) do
      nil ->
        # Default voice settings
        %{
          languageCode: "en-US",
          name: "en-US-Standard-A",
          ssmlGender: "FEMALE"
        }

      settings ->
        %{
          languageCode: settings.language_code,
          name: settings.name,
          ssmlGender: settings.ssml_gender
        }
    end
  end

  defp load_credentials do
    case Application.get_env(:altar, :google)[:credentials_json] do
      {:system, env_var} ->
        System.get_env(env_var) |> Jason.decode!()

      json_string when is_binary(json_string) ->
        Jason.decode!(json_string)

      _ ->
        raise "Google credentials not configured"
    end
  end

  defp get_access_token(credentials) do
    # Simplified version - use Goth in production
    {:ok, token} = Goth.fetch(credentials)
    token.token
  end
end
