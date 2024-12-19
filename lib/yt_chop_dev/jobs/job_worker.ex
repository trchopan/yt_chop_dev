defmodule YtChopDev.Jobs.JobWorker do
  require Logger

  alias Broadway.Message

  def catch_all_error(message, error, job) do
    message
    |> Message.put_data({:error, error, job})
    |> Message.failed(:catch_all)
  end

  def handle_failed_silence(messages) do
    messages
    |> Enum.map(fn %Message{data: {:error, error, job}} = msg ->
      Logger.error("#{__MODULE__} failed job #{job.id}")
      Logger.debug(inspect(error))
      Message.configure_ack(msg, on_failure: :discard)
    end)
  end
end
