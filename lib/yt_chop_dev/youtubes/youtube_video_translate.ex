defmodule YtChopDev.Youtubes.YoutubeVideoTranslate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "youtube_video_translates" do
    field :video_id, :string
    field :public_url, :string
    field :filename, :string
    field :language, Ecto.Enum, values: [:vie, :jap, :kor]
    field :gender, Ecto.Enum, values: [:male, :female]
    field :version, :string
    field :transcript, :string

    belongs_to :youtube_video, YtChopDev.Youtubes.YoutubeVideo,
      foreign_key: :youtube_video_id,
      on_replace: :update

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(youtube_video_translate, attrs) do
    youtube_video_translate
    |> cast(attrs, [
      :video_id,
      :public_url,
      :filename,
      :language,
      :gender,
      :version,
      :transcript
    ])
    |> validate_required([
      :video_id,
      :language,
      :gender,
      :version,
      :transcript
    ])
    |> foreign_key_constraint(:youtube_video_id)
  end

  def transcript(transcript) when is_binary(transcript) do
    transcript
    |> TimestampSplitter.split_timestamps()
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
