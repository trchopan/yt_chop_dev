defmodule YtChopDevWeb.YoutubeVideoLive.FormComponent do
  use YtChopDevWeb, :live_component

  alias YtChopDev.Youtubes.YoutubeInfoUtils

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="youtube_video-form"
        phx-target={@myself}
        phx-submit="navigate"
      >
        <div class="flex gap-2">
          <div class="flex-grow">
            <.input field={@form[:youtube_url]} label="Youtube URL" />
          </div>
          <div class="pt-[33px]">
            <.button phx-disable-with="Checking...">🚀</.button>
          </div>
        </div>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(%{"youtube_url" => ""}))}
  end

  @impl true
  def handle_event("navigate", %{"youtube_url" => youtube_url} = params, socket) do
    youtube_id = YoutubeInfoUtils.youtube_id_from_url(youtube_url)

    case YoutubeInfoUtils.get_video_information(youtube_id) do
      {:ok, youtube_info} ->
        IO.inspect(youtube_info["id"], label: "youtube_info")
        {:noreply, push_navigate(socket, to: ~p"/v/#{youtube_id}")}

      {:error, details} ->
        errorDetail = Map.get(details, "error", details)
        form = to_form(params, errors: [youtube_url: errorDetail])
        {:noreply, socket |> assign(form: form)}
    end
  end
end
