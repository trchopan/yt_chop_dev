defmodule YtChopDev.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "jobs" do
    field :args, :map
    field :name, Ecto.Enum, values: [:youtube_translate]
    field :status, Ecto.Enum, values: [:queued, :running, :done, :failed]
    field :metadata, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:name, :args, :status, :metadata])
    |> validate_required([:name, :status])
  end
end
