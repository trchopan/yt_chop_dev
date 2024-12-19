defmodule YtChopDevWeb.YoutubeVideoLive.Index do
  alias YtChopDev.Jobs
  use YtChopDevWeb, :live_view

  alias YtChopDev.Youtubes
  alias YtChopDev.Youtubes.YoutubeInfoUtils

  @impl true
  def mount(_params, _session, socket) do
    videos =
      Youtubes.latest_youtube_videos_has_translates(30)
      |> Enum.map(&Youtubes.preload_youtube_video_translates/1)

    jobs = Jobs.list_pending_jobs()

    socket =
      socket
      |> stream(:youtube_videos, videos)
      |> assign(:jobs, jobs)
      |> assign(:limit, 10)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Youtube videos")
  end
end
