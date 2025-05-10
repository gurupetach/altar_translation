# lib/altar_web/live/translator_live/index.ex
defmodule AltarWeb.TranslatorLive.Index do
  use AltarWeb, :live_view
  alias Altar.YouTube.UrlValidator
  alias Altar.Translation.Service
  alias Altar.Audio.Processor

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:youtube_url, "")
      |> assign(:target_language, "sw")
      |> assign(:status, :idle)
      |> assign(:error, nil)
      |> assign(:transcripts, [])
      |> assign(:processor_pid, nil)
      |> assign(:languages, Service.supported_languages())

    {:ok, socket}
  end

  @impl true
  def handle_event("update_url", %{"youtube_url" => url}, socket) do
    {:noreply, assign(socket, :youtube_url, url)}
  end

  @impl true
  def handle_event("update_language", %{"language" => language}, socket) do
    {:noreply, assign(socket, :target_language, language)}
  end

  @impl true
  def handle_event("start_translation", _params, socket) do
    case UrlValidator.validate_url(socket.assigns.youtube_url) do
      {:ok, _video_id} ->
        # Start the audio processor without checking if it's live
        {:ok, pid} =
          Processor.start_link(%{
            stream_url: socket.assigns.youtube_url,
            target_language: socket.assigns.target_language,
            parent_pid: self()
          })

        Processor.start_processing(pid)

        socket =
          socket
          |> assign(:status, :processing)
          |> assign(:processor_pid, pid)
          |> assign(:error, nil)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, assign(socket, :error, reason)}
    end
  end

  @impl true
  def handle_event("stop_translation", _params, socket) do
    if socket.assigns.processor_pid do
      Processor.stop_processing(socket.assigns.processor_pid)
    end

    socket =
      socket
      |> assign(:status, :idle)
      |> assign(:processor_pid, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:translation_update, update}, socket) do
    transcripts = [update | socket.assigns.transcripts] |> Enum.take(50)
    {:noreply, assign(socket, :transcripts, transcripts)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">YouTube Audio Translator</h1>

      <div class="bg-white shadow-md rounded-lg p-6 mb-6">
        <form phx-change="update_url" phx-submit="start_translation" class="space-y-4">
          <div>
            <label for="youtube_url" class="block text-sm font-medium text-gray-700 mb-1">
              YouTube URL
            </label>
            <input
              type="text"
              id="youtube_url"
              name="youtube_url"
              value={@youtube_url}
              placeholder="https://www.youtube.com/watch?v=..."
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={@status == :processing}
            />
          </div>

          <div>
            <label for="language" class="block text-sm font-medium text-gray-700 mb-1">
              Target Language
            </label>
            <select
              id="language"
              name="language"
              phx-change="update_language"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={@status == :processing}
            >
              <%= for {code, name} <- @languages, code != "en" do %>
                <option value={code} selected={code == @target_language}>
                  {name}
                </option>
              <% end %>
            </select>
          </div>

          <%= if @error do %>
            <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
              {@error}
            </div>
          <% end %>

          <div class="flex gap-4">
            <%= if @status == :idle do %>
              <button
                type="submit"
                class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded disabled:opacity-50"
                disabled={@youtube_url == ""}
              >
                Start Translation
              </button>
            <% else %>
              <button
                type="button"
                phx-click="stop_translation"
                class="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded"
              >
                Stop Translation
              </button>
            <% end %>
          </div>
        </form>
      </div>

      <%= if @status == :processing do %>
        <div class="bg-white shadow-md rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Live Translation</h2>

          <div class="animate-pulse mb-4">
            <div class="flex items-center space-x-2">
              <div class="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
              <span class="text-sm text-gray-600">Processing audio...</span>
            </div>
          </div>

          <div class="space-y-4 max-h-96 overflow-y-auto">
            <%= for transcript <- @transcripts do %>
              <div class="border-b pb-4">
                <div class="text-sm text-gray-600">
                  {DateTime.from_unix!(transcript.timestamp) |> Calendar.strftime("%H:%M:%S")}
                </div>
                <div class="font-medium text-gray-900">
                  Original: {transcript.original}
                </div>
                <div class="text-blue-600">
                  Translation: {transcript.translated}
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
