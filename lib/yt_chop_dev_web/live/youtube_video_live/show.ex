defmodule YtChopDevWeb.YoutubeVideoLive.Show do
  require Logger
  alias YtChopDev.Jobs.JobAgent
  alias YtChopDev.Jobs
  alias YtChopDev.Youtubes.YoutubeInfoUtils
  use YtChopDevWeb, :live_view

  alias YtChopDev.Youtubes

  @impl true
  def mount(%{"id" => id} = params, _session, socket) do
    video = Youtubes.get_youtube_video_by_video_id(id)

    video =
      if video != nil do
        video
      else
        Logger.info("#{id} > Get video info from youtube")

        with {:ok, video_info} <- YoutubeInfoUtils.get_video_information(id),
             {:ok, video} <- Youtubes.create_youtube_video_from_video_info(video_info) do
          video
        else
          err ->
            Logger.info(inspect(err))
            put_flash(socket, :error, "Could not find video with id #{id}")

            nil
        end
      end

    translates = Youtubes.list_youtube_video_translates_of_youtube_video(video.video_id)

    language = Map.get(params, "language", "vie")
    gender = Map.get(params, "gender", "male")

    IO.inspect(language, label: "language")
    IO.inspect(gender, label: "gender")

    translate =
      if language != nil and gender != nil do
        translates
        |> Enum.filter(
          &(&1.language == String.to_existing_atom(language) and
              &1.gender == String.to_existing_atom(gender))
        )
        |> Enum.at(0)
      else
        nil
      end

    request_form = to_form(%{"language" => language, "gender" => gender})

    socket =
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:youtube_video, video)
      |> assign(:youtube_video_translates, translates)
      |> assign(:translate, translate)
      |> assign(:request_form, request_form)
      |> assign(:request_form_error, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "request_translate",
        %{"language" => language, "gender" => gender} = _params,
        socket
      ) do
    video = socket.assigns.youtube_video
    {:ok, video_info} = YoutubeInfoUtils.get_video_information(video.video_id)

    with :ok <- check_video_length(video_info),
         :ok <- check_already_translated(video, language, gender),
         :ok <- check_job_limit(),
         :ok <- check_existing_job(video, language, gender) do
      {:ok, job} =
        Jobs.create_job(%{
          args: %{"video_id" => video.video_id, "language" => language, "gender" => gender},
          name: :youtube_translate,
          status: :queued
        })

      JobAgent.queue_job(job)
      {:noreply, socket}
    else
      {:error, details} ->
        {:noreply, socket |> assign(:request_form_error, details)}
    end
  end

  def check_video_length(video_info) do
    if video_info["lengthSeconds"] > 30 * 60 do
      {:error, "Video too long (max 30 minutes)"}
    else
      :ok
    end
  end

  def check_already_translated(video, language, gender) do
    translate = Youtubes.get_youtube_video_translate_by_video_id(video.video_id, language, gender)

    if translate != nil do
      {:error, "Already translated"}
    else
      :ok
    end
  end

  def check_job_limit() do
    jobs = Jobs.list_pending_jobs()

    if length(jobs) >= 10 do
      {:error, "Can only queue 10 videos. Please try again later."}
    else
      :ok
    end
  end

  def check_existing_job(video, language, gender) do
    jobs = Jobs.get_jobs_for_youtube_translate(video.video_id, language, gender)

    if jobs |> Enum.any?(fn job -> job.status == :running or job.status == :queued end) do
      {:error, "Existing translate job for video"}
    else
      :ok
    end
  end

  def parse_transcript_row(row) do
    [start, text] = row |> String.split(">>>") |> Enum.map(&String.trim/1)

    {start, _} = Integer.parse(start)

    minutes = div(start, 60)
    seconds = rem(start, 60)

    formatted_time = "#{minutes}:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"

    {formatted_time, text}
  end

  defp page_title(:show), do: "Youtube video"
end
