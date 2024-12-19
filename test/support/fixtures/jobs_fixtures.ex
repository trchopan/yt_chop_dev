defmodule YtChopDev.JobsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `YtChopDev.Jobs` context.
  """

  @doc """
  Generate a job.
  """
  def job_fixture(attrs \\ %{}) do
    {:ok, job} =
      attrs
      |> Enum.into(%{
        args: %{},
        metadata: %{},
        name: "some name",
        status: "some status"
      })
      |> YtChopDev.Jobs.create_job()

    job
  end
end
