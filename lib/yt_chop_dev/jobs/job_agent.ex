defmodule YtChopDev.Jobs.JobAgent do
  @moduledoc """
  A module to map the job type to buffer

  Because the buffer is in memory, we requeue all the running jobs during startup.
  """
  alias YtChopDev.Jobs
  alias YtChopDev.Jobs.Job
  use Agent

  require Logger

  def start_link(setups) do
    Process.spawn(
      fn ->
        :timer.sleep(3000)
        requeue_jobs()
      end,
      [:link]
    )

    Agent.start_link(fn -> setups end, name: __MODULE__)
  end

  def queue_job(%Job{name: job_type} = job) do
    setups = Agent.get(__MODULE__, & &1)

    buffer =
      case job_type do
        :youtube_translate -> :youtube_translate_buffer
      end

    OffBroadwayMemory.Buffer.push(setups[buffer], job)
  end

  def requeue_jobs() do
    pending_jobs =
      Jobs.list_pending_jobs()
      |> Enum.map(&Jobs.update_job(&1, %{status: :queued}))
      |> Enum.map(&elem(&1, 1))

    Logger.info("Requeue running jobs #{length(pending_jobs)}")
    pending_jobs |> Enum.map(&queue_job/1)
  end
end
