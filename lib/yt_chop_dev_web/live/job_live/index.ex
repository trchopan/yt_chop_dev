defmodule YtChopDevWeb.JobLive.Index do
  alias YtChopDev.Helpers
  alias YtChopDev.Youtubes
  use YtChopDevWeb, :live_view

  alias YtChopDev.Jobs
  alias YtChopDev.Youtubes.YoutubeInfoUtils

  @impl true
  def mount(_params, _session, socket) do
    jobs = Jobs.list_jobs(10)
    video_ids = jobs |> Enum.map(fn j -> j.args["video_id"] end) |> Enum.uniq()
    videos = Youtubes.get_multi_youtube_videos_by_ids(video_ids)

    socket =
      socket
      |> assign(:jobs, jobs)
      |> assign(:videos, videos)
      |> assign(:limit, 10)

    {:ok, socket}
  end

  def find_video(job, videos) do
    videos |> Enum.find(fn v -> v.video_id == job.args["video_id"] end)
  end

  def filter_pending_jobs(jobs) do
    jobs
    |> Enum.filter(fn j ->
      j.status == :queued or j.status == :running
    end)
  end

  def format_job_duration(job) do
    duration = DateTime.diff(job.updated_at, job.inserted_at, :second)
    Helpers.format_seconds(duration)
  end
end
