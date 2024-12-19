defmodule YtChopDev.YoutubesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `YtChopDev.Youtubes` context.
  """

  @doc """
  Generate a youtube_video.
  """
  def youtube_video_fixture(attrs \\ %{}) do
    {:ok, youtube_video} =
      attrs
      |> Enum.into(%{
        author: "some author",
        description: "some description",
        thumbnail: "some thumbnail",
        transcript: "some transcript",
        video_id: "some video_id"
      })
      |> YtChopDev.Youtubes.create_youtube_video()

    youtube_video
  end

  @doc """
  Generate a youtube_video_translate.
  """
  def youtube_video_translate_fixture(attrs \\ %{}) do
    {:ok, youtube_video_translate} =
      attrs
      |> Enum.into(%{
        filename: "some filename",
        gender: "some gender",
        language: "some language",
        public_url: "some public_url",
        version: "some version",
        video_id: "some video_id"
      })
      |> YtChopDev.Youtubes.create_youtube_video_translate()

    youtube_video_translate
  end
end
