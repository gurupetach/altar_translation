# lib/altar/youtube/url_validator.ex
defmodule Altar.YouTube.UrlValidator do
  @moduledoc """
  Validates YouTube URLs and checks if they are live streams
  """

  @youtube_regex ~r/^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/

  def validate_url(url) when is_binary(url) do
    case Regex.run(@youtube_regex, url) do
      [_, video_id] -> {:ok, video_id}
      _ -> {:error, "Invalid YouTube URL format"}
    end
  end

  def validate_url(_), do: {:error, "URL must be a string"}

  def is_live_stream?(video_id) do
    # This would typically make an API call to YouTube Data API
    # For now, we'll return a mock response
    # In production, you'd use the YouTube Data API v3
    case mock_youtube_api_call(video_id) do
      {:ok, %{live: true}} -> {:ok, true}
      {:ok, %{live: false}} -> {:error, "This is not a live stream"}
      {:error, reason} -> {:error, reason}
    end
  end

  defp mock_youtube_api_call(_video_id) do
    # Mock implementation - replace with actual YouTube Data API call
    {:ok, %{live: true}}
  end
end
