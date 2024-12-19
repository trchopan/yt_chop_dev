defmodule YtChopDevWeb.YoutubeVideoLive.Index do
  alias YtChopDev.Jobs
  use YtChopDevWeb, :live_view

  alias YtChopDev.Youtubes
  alias YtChopDev.Youtubes.YoutubeInfoUtils

  @impl true
  def mount(_params, _session, socket) do
    limit = 30

    videos =
      Youtubes.latest_youtube_videos_with_translates(0, limit)
      |> Enum.map(&Youtubes.preload_youtube_video_translates/1)

    jobs = Jobs.list_pending_jobs()

    socket =
      socket
      |> stream(:youtube_videos, videos)
      |> assign(:jobs, jobs)
      |> assign(:page, 0)
      |> assign(:limit, limit)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("load_more_videos", _params, socket) do
    page = socket.assigns.page + 1
    limit = socket.assigns.limit

    videos =
      (Youtubes.latest_youtube_videos_with_translates(page, limit) || [])
      |> Enum.map(&Youtubes.preload_youtube_video_translates/1)

    IO.inspect(videos |> Enum.map(& &1.title), label: "videos")

    socket =
      socket
      |> assign(:page, page)
      |> stream(:youtube_videos, videos)

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Youtube Translations by chop.dev")
  end
end
