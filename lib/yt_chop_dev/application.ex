defmodule YtChopDev.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    broadway_children = make_broadway_children()

    application_children = [
      YtChopDevWeb.Telemetry,
      YtChopDev.Repo,
      {DNSCluster, query: Application.get_env(:yt_chop_dev, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: YtChopDev.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: YtChopDev.Finch},
      # Start a worker by calling: YtChopDev.Worker.start_link(arg)
      # {YtChopDev.Worker, arg},
      # Start to serve requests, typically the last entry
      YtChopDevWeb.Endpoint
    ]

    children = broadway_children ++ application_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: YtChopDev.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YtChopDevWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp make_broadway_children do
    broadway_configs =
      [
        {YtChopDev.Jobs.JobWorkerYoutubeTranslate, :youtube_translate_buffer}
      ]

    children =
      broadway_configs
      |> Enum.map(fn {worker, buffer} ->
        # Create buffer and connect them with worker module
        [
          Supervisor.child_spec({OffBroadwayMemory.Buffer, name: buffer}, id: buffer),
          {worker, buffer: buffer}
        ]
      end)
      |> List.flatten()

    job_agent =
      {
        YtChopDev.Jobs.JobAgent,
        broadway_configs
        |> Enum.map(fn {_, buffer} ->
          # Config for buffer id is the same as buffer atom
          {buffer, buffer}
        end)
      }

    children ++ [job_agent]
  end
end
