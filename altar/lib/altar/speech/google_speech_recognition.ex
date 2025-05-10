# lib/altar/speech/google_speech_recognition.ex
defmodule Altar.Speech.GoogleSpeechRecognition do
  @moduledoc """
  Google Cloud Speech-to-Text API implementation
  """

  use GenServer
  require Logger

  @api_endpoint "https://speech.googleapis.com/v1/speech:recognize"

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def recognize_audio(pid, audio_data) do
    GenServer.call(pid, {:recognize, audio_data})
  end

  # Server callbacks

  def init(opts) do
    state = %{
      language_code: opts[:language_code] || "en-US",
      credentials: load_credentials()
    }

    {:ok, state}
  end

  def handle_call({:recognize, audio_data}, _from, state) do
    result = perform_recognition(audio_data, state)
    {:reply, result, state}
  end

  defp perform_recognition(audio_data, state) do
    request_body = %{
      config: %{
        encoding: "LINEAR16",
        sampleRateHertz: 16000,
        languageCode: state.language_code,
        enableAutomaticPunctuation: true
      },
      audio: %{
        content: Base.encode64(audio_data)
      }
    }

    headers = [
      {"Authorization", "Bearer #{get_access_token(state.credentials)}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(@api_endpoint, Jason.encode!(request_body), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        parse_response(body)

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Speech API error: #{status_code} - #{body}")
        {:error, "API error: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Network error: #{reason}")
        {:error, "Network error: #{reason}"}
    end
  end

  defp parse_response(body) do
    case Jason.decode(body) do
      {:ok, %{"results" => results}} when is_list(results) and length(results) > 0 ->
        transcript =
          results
          |> Enum.map(fn %{"alternatives" => [%{"transcript" => text} | _]} -> text end)
          |> Enum.join(" ")

        {:ok, transcript}

      {:ok, _} ->
        # No speech detected
        {:ok, ""}

      {:error, _} ->
        {:error, "Failed to parse response"}
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
    # This is a simplified version. In production, you'd use Goth library
    # to handle OAuth2 token management properly
    {:ok, token} = Goth.fetch(credentials)
    token.token
  end
end
