# lib/altar/speech/recognition.ex
defmodule Altar.Speech.Recognition do
  @moduledoc """
  Handles speech-to-text conversion using external APIs
  """

  use GenServer
  require Logger

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def process_audio_chunk(pid, audio_chunk) do
    GenServer.cast(pid, {:process_chunk, audio_chunk})
  end

  # Server callbacks

  def init(opts) do
    state = %{
      callback_pid: opts[:callback_pid],
      language: opts[:language] || "en-US",
      provider: opts[:provider] || :google
    }

    {:ok, state}
  end

  def handle_cast({:process_chunk, audio_chunk}, state) do
    case recognize_speech(audio_chunk, state) do
      {:ok, transcript} ->
        send(state.callback_pid, {:transcript, transcript})

      {:error, reason} ->
        Logger.error("Speech recognition error: #{reason}")
    end

    {:noreply, state}
  end

  defp recognize_speech(audio_chunk, %{provider: :google} = state) do
    # This would integrate with Google Speech-to-Text API
    # For demo purposes, we'll return mock data
    mock_google_speech_api(audio_chunk, state.language)
  end

  defp mock_google_speech_api(_audio_chunk, _language) do
    # Simulate API response
    Process.sleep(100)

    transcripts = [
      "Welcome to this live stream",
      "Today we'll be discussing Phoenix LiveView",
      "Real-time translation is fascinating",
      "The audio processing pipeline is complex"
    ]

    {:ok, Enum.random(transcripts)}
  end
end
