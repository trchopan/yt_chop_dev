defmodule YtChopDev.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :args, :map
      add :status, :string
      add :metadata, :map

      timestamps(type: :utc_datetime)
    end
  end
end
