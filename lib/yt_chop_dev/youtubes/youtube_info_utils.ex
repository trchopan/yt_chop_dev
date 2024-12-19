defmodule YtChopDev.Youtubes.YoutubeInfoUtils do
  require Logger

  def download_binary(url) do
    Req.get(url)
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end

  def get_video_url(video_info) do
    found =
      video_info["adaptiveFormats"]
      |> Enum.find(fn e ->
        if e["resolution"] do
          resolution = Integer.parse(e["resolution"]) |> elem(0)
          resolution > 720 and e["container"] == "mp4"
        else
          false
        end
      end)

    if found == nil do
      {:error, "No suitable video found"}
    else
      {:ok, found["url"]}
    end
  end

  def get_audio_url(video_info) do
    found =
      video_info["adaptiveFormats"]
      |> Enum.find(fn e ->
        e["type"] =~ ~r/audio\/mp4.*/ and e["encoding"] == "aac"
      end)

    if found == nil do
      {:error, "No suitable audio found"}
    else
      {:ok, found["url"]}
    end
  end

  def get_video_information(youtube_id) do
    Req.get(
      url: Application.get_env(:yt_chop_dev, :youtube_info_api) <> "/#{youtube_id}",
      headers: [{"content-type", "application/json"}]
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, response} ->
        {:error, response.body}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end

  def validate_youtube_url(url) when is_binary(url) do
    regex =
      ~r/^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/(watch\?v=|embed\/|v\/|.+\?v=)?([^&=%\?]{11})/

    case Regex.match?(regex, url) do
      true -> {:ok, "Valid YouTube URL"}
      false -> {:error, "Invalid YouTube URL"}
    end
  end

  def validate_youtube_url(_), do: {:error, "Invalid input"}

  def youtube_id_from_url(url) do
    regex = ~r/(?:v=|\/)([0-9A-Za-z_-]{11})/

    case Regex.run(regex, url) do
      [_, video_id] -> video_id
      _ -> nil
    end
  end

  def make_youtube_thumbnail_url(video_id) do
    "https://img.youtube.com/vi/#{video_id}/sddefault.jpg"
  end
end
