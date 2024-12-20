defmodule YtChopDev.Youtubes.YoutubeVideo do
  use Ecto.Schema
  import Ecto.Changeset
  alias YtChopDev.Helpers

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "youtube_videos" do
    field :video_id, :string
    field :title, :string
    field :description, :string
    field :author, :string
    field :published_at, :naive_datetime
    field :transcript, :string

    has_many :youtube_video_translates, YtChopDev.Youtubes.YoutubeVideoTranslate

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(youtube_video, attrs) do
    youtube_video
    |> cast(attrs, [
      :video_id,
      :title,
      :description,
      :author,
      :published_at,
      :transcript
    ])
    |> validate_required([
      :video_id,
      :title,
      :description,
      :author,
      :published_at
    ])
  end

  def transcript(transcript) when is_binary(transcript) do
    transcript
    |> Helpers.split_timestamps()
    |> Enum.map(fn t ->
      [start, text] = t |> String.split(">>>") |> Enum.map(&String.trim/1)
      {start, _} = Float.parse(start)
      {start, text}
    end)
  end

  def to_transcript(transcripts) do
    transcripts
    |> Enum.map(fn {start, text} -> "#{start} >>> #{text}" end)
    |> Enum.join("\n")
  end
end
