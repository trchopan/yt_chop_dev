defmodule YtChopDev.Repo.Migrations.CreateYoutubeVideos do
  use Ecto.Migration

  def change do
    create table(:youtube_videos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :video_id, :string
      add :title, :string
      add :description, :text
      add :author, :string
      add :published_at, :naive_datetime
      add :transcript, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:youtube_videos, [:video_id])
  end
end
