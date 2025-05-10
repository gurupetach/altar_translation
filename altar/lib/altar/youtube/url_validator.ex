# lib/altar/youtube/url_validator.ex
defmodule Altar.YouTube.UrlValidator do
  @moduledoc """
  Validates YouTube URLs without checking if they are live streams
  """

  @youtube_regex ~r/^(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/

  def validate_url(url) when is_binary(url) do
    case Regex.run(@youtube_regex, url) do
      [_, video_id] -> {:ok, video_id}
      _ -> {:error, "Invalid YouTube URL format"}
    end
  end

  def validate_url(_), do: {:error, "URL must be a string"}
end
