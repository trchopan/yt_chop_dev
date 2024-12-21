defmodule YtChopDevWeb.YoutubeVideoLive.Show do
  require Logger
  alias YtChopDev.Recaptcha
  alias YtChopDev.Helpers
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
      |> assign(:page_title, video.title <> " - yt.chop.dev")
      |> assign(:youtube_video, video)
      |> assign(:youtube_video_translates, translates)
      |> assign(:translate, translate)
      |> assign(:request_form, request_form)
      |> assign(:form2, to_form(%{}))
      |> assign(:request_form_error, nil)
      |> assign(:show_translate, true)
      |> push_event("reset-recaptcha", %{})

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "request_translate",
        %{"language" => language, "gender" => gender} = params,
        socket
      ) do
    token = params["g-recaptcha-response"]

    if token == nil do
      {:noreply, socket |> push_event("reset-recaptcha", %{})}
    else
      video = socket.assigns.youtube_video
      {:ok, video_info} = YoutubeInfoUtils.get_video_information(video.video_id)

      with :ok <- must_valid_recaptcha_token(token),
           :ok <- must_valid_video_length(video_info, 30),
           :ok <- must_have_caption_english(video_info),
           :ok <- must_not_reach_job_limit(),
           :ok <- must_not_existing_job(video, language, gender) do
        should_force =
          case check_already_translated(video, language, gender) do
            :ok ->
              false

            {:error, _} ->
              true
          end

        {:ok, job} =
          Jobs.create_job(%{
            args: %{
              "video_id" => video.video_id,
              "language" => language,
              "gender" => gender,
              "force_translate" => should_force
            },
            name: :youtube_translate,
            status: :queued
          })

        JobAgent.queue_job(job)
        {:noreply, socket |> push_navigate(to: ~p"/jobs")}
      else
        {:error, details} ->
          {:noreply,
           socket |> assign(:request_form_error, details) |> push_event("reset-recaptcha", %{})}
      end
    end
  end

  def must_valid_recaptcha_token(token) do
    IO.inspect(token)

    with {:ok, true} <- Recaptcha.verify(token, "youtube_translate") do
      :ok
    else
      error ->
        Logger.debug("Recaptcha error: #{inspect(error)}")
        {:error, "Invalid reCAPTCHA"}
    end
  end

  def must_valid_video_length(video_info, minutes) do
    if video_info["lengthSeconds"] > minutes * 60 do
      {:error, "Video too long (max 30 minutes)"}
    else
      :ok
    end
  end

  def must_have_caption_english(video_info) do
    found_en_caption =
      video_info["captions"]
      |> Enum.find(fn e -> Enum.member?(["en", "en-US"], e["language_code"]) end)

    if found_en_caption == nil do
      {:error, "Video does not have English caption"}
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

  def must_not_reach_job_limit() do
    jobs = Jobs.list_pending_jobs()

    if length(jobs) >= 10 do
      {:error, "Can only queue 10 videos. Please try again later."}
    else
      :ok
    end
  end

  def must_not_existing_job(video, language, gender) do
    jobs = Jobs.get_jobs_for_youtube_translate(video.video_id, language, gender)

    if jobs |> Enum.any?(fn job -> job.status == :running or job.status == :queued end) do
      {:error, "Existing translate job for video"}
    else
      :ok
    end
  end

  def format_transcript_row(row) do
    [start, content] = row |> String.split(">>>") |> Enum.map(&String.trim/1)
    {start, _} = Integer.parse(start)
    formatted_time = Helpers.format_seconds(start)
    {formatted_time, content}
  end

  def format_transcript(transcript) do
    transcript
    |> Helpers.split_timestamps()
    |> Enum.map(&format_transcript_row/1)
  end
end
