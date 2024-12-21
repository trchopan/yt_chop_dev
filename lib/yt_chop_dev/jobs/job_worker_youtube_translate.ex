defmodule YtChopDev.Jobs.JobWorkerYoutubeTranslate do
  require Logger
  use Broadway

  alias YtChopDev.Youtubes
  alias YtChopDev.Youtubes.YoutubeTranslateUtils
  alias YtChopDev.Jobs
  alias YtChopDev.Jobs.JobWorker
  alias YtChopDev.Jobs.Job
  alias Broadway.Message

  def start_link(opts) do
    Logger.info("#{__MODULE__} starting")

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          # OffBroadwayMemory.Producer,
          YtChopDev.OffBroadwayMemory.ProducerCustom,
          buffer: opts[:buffer]
        },
        concurrency: 1
      ],
      processors: [default: [concurrency: 3]],
      batchers: [
        default: [
          batch_size: 1,
          batch_timeout: 1_000
        ]
      ]
    )
  end

  def handle_youtube_translate(%Job{} = job) do
    video_id = job.args["video_id"]
    language = job.args["language"]
    gender = job.args["gender"]
    force_translate = job.args["force_translate"]
    force_transcript = job.args["force_transcript"]

    try do
      video = Youtubes.get_youtube_video_by_video_id(video_id)

      with {:ok, video, translate} <-
             YoutubeTranslateUtils.youtube_translate(video, language, gender,
               force_translate: force_translate,
               force_transcript: force_transcript,
               cleanup: true
             ) do
        {:ok, video, translate}
      end
    rescue
      exception ->
        Logger.error(inspect(exception))
        {:error, inspect(exception)}
    end
  end

  def handle_message(
        _processor,
        %Message{data: %Job{name: :youtube_translate} = job} = message,
        _
      ) do
    with {:ok, job} <- job |> Jobs.update_job(%{status: :running, status_metadata: %{}}),
         {:ok, _video, _translate} <- handle_youtube_translate(job),
         {:ok, job} <- job |> Jobs.update_job(%{status: :done}) do
      message |> Message.put_data(job)
    else
      error ->
        JobWorker.catch_all_error(message, error, job)
    end
  end

  def handle_failed(messages, _) do
    JobWorker.handle_failed_silence(messages)
  end

  def handle_batch(_batch, messages, _, _) do
    messages
  end
end
