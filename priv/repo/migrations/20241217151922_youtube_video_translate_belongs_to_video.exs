defmodule YtChopDev.Repo.Migrations.YoutubeVideoTranslateBelongsToVideo do
  use Ecto.Migration

  def change do
    alter table(:youtube_video_translates) do
      add :youtube_video_id, references(:youtube_videos, on_delete: :delete_all, type: :binary_id)
    end
  end
end
