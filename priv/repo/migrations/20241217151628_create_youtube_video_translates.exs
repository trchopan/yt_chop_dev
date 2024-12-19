defmodule YtChopDev.Repo.Migrations.CreateYoutubeVideoTranslates do
  use Ecto.Migration

  def change do
    create table(:youtube_video_translates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :video_id, :string
      add :public_url, :string
      add :filename, :string
      add :language, :string
      add :gender, :string
      add :version, :string
      add :transcript, :text

      timestamps(type: :utc_datetime)
    end
  end
end
