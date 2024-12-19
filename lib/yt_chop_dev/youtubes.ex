defmodule YtChopDev.Youtubes do
  @moduledoc """
  The Youtubes context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias YtChopDev.Repo
  alias YtChopDev.Youtubes.YoutubeVideo
  alias YtChopDev.Youtubes.YoutubeVideoTranslate

  @doc """
  Returns the list of youtube_videos.

  ## Examples

      iex> list_youtube_videos()
      [%YoutubeVideo{}, ...]

  """
  def list_youtube_videos do
    Repo.all(YoutubeVideo)
  end

  def latest_youtube_videos(limit) do
    Repo.all(from y in YoutubeVideo, order_by: [desc: y.updated_at], limit: ^limit)
  end

  def latest_youtube_videos_with_translates(page, limit) do
    offset = page * limit + 1

    query =
      from v in YoutubeVideo,
        select: v,
        join: t in YoutubeVideoTranslate,
        on: t.youtube_video_id == v.id,
        group_by: v.id,
        having: count(t.id) > 0,
        order_by: [desc: v.updated_at],
        limit: ^limit,
        offset: ^offset

    Repo.all(query)
  end

  def preload_youtube_video_translates(video) do
    video |> Repo.preload(:youtube_video_translates)
  end

  @doc """
  Gets a single youtube_video.

  Raises `Ecto.NoResultsError` if the Youtube video does not exist.

  ## Examples

      iex> get_youtube_video!(123)
      %YoutubeVideo{}

      iex> get_youtube_video!(456)
      ** (Ecto.NoResultsError)

  """
  def get_youtube_video!(id), do: Repo.get!(YoutubeVideo, id)

  def get_youtube_video_by_video_id(id) do
    Repo.one(from y in YoutubeVideo, where: y.video_id == ^id)
  end

  def get_multi_youtube_videos_by_ids(ids) do
    Repo.all(from y in YoutubeVideo, where: y.video_id in ^ids)
  end

  @doc """
  Creates a youtube_video.

  ## Examples

      iex> create_youtube_video(%{field: value})
      {:ok, %YoutubeVideo{}}

      iex> create_youtube_video(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_youtube_video(attrs \\ %{}) do
    %YoutubeVideo{}
    |> YoutubeVideo.changeset(attrs)
    |> Repo.insert()
  end

  def create_youtube_video_from_video_info(video_info) do
    create_youtube_video(%{
      video_id: video_info["videoId"],
      title: video_info["title"],
      description: video_info["description"],
      author: video_info["author"],
      published_at: DateTime.from_unix!(video_info["published"], :second)
    })
  end

  @doc """
  Updates a youtube_video.

  ## Examples

      iex> update_youtube_video(youtube_video, %{field: new_value})
      {:ok, %YoutubeVideo{}}

      iex> update_youtube_video(youtube_video, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_youtube_video(%YoutubeVideo{} = youtube_video, attrs) do
    youtube_video
    |> YoutubeVideo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a youtube_video.

  ## Examples

      iex> delete_youtube_video(youtube_video)
      {:ok, %YoutubeVideo{}}

      iex> delete_youtube_video(youtube_video)
      {:error, %Ecto.Changeset{}}

  """
  def delete_youtube_video(%YoutubeVideo{} = youtube_video) do
    Repo.delete(youtube_video)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking youtube_video changes.

  ## Examples

      iex> change_youtube_video(youtube_video)
      %Ecto.Changeset{data: %YoutubeVideo{}}

  """
  def change_youtube_video(%YoutubeVideo{} = youtube_video, attrs \\ %{}) do
    YoutubeVideo.changeset(youtube_video, attrs)
  end

  @doc """
  Returns the list of youtube_video_translates.

  ## Examples

      iex> list_youtube_video_translates()
      [%YoutubeVideoTranslate{}, ...]

  """
  def list_youtube_video_translates do
    Repo.all(YoutubeVideoTranslate)
  end

  def list_youtube_video_translates_of_youtube_video(youtube_video_id) do
    Repo.all(from y in YoutubeVideoTranslate, where: y.video_id == ^youtube_video_id)
  end

  @doc """
  Gets a single youtube_video_translate.

  Raises `Ecto.NoResultsError` if the Youtube video translate does not exist.

  ## Examples

      iex> get_youtube_video_translate!(123)
      %YoutubeVideoTranslate{}

      iex> get_youtube_video_translate!(456)
      ** (Ecto.NoResultsError)

  """
  def get_youtube_video_translate!(id), do: Repo.get!(YoutubeVideoTranslate, id)

  def get_youtube_video_translate_by_video_id(video_id, language, gender) do
    Repo.one(
      from y in YoutubeVideoTranslate,
        where: y.video_id == ^video_id and y.language == ^language and y.gender == ^gender
    )
  end

  @doc """
  Creates a youtube_video_translate.

  ## Examples

      iex> create_youtube_video_translate(%{field: value})
      {:ok, %YoutubeVideoTranslate{}}

      iex> create_youtube_video_translate(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_youtube_video_translate_for_youtube_video(%YoutubeVideo{} = video, attrs \\ %{}) do
    %YoutubeVideoTranslate{}
    |> YoutubeVideoTranslate.changeset(attrs)
    |> put_assoc(:youtube_video, video)
    |> Repo.insert()
  end

  @doc """
  Updates a youtube_video_translate.

  ## Examples

      iex> update_youtube_video_translate(youtube_video_translate, %{field: new_value})
      {:ok, %YoutubeVideoTranslate{}}

      iex> update_youtube_video_translate(youtube_video_translate, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_youtube_video_translate(%YoutubeVideoTranslate{} = youtube_video_translate, attrs) do
    youtube_video_translate
    |> YoutubeVideoTranslate.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a youtube_video_translate.

  ## Examples

      iex> delete_youtube_video_translate(youtube_video_translate)
      {:ok, %YoutubeVideoTranslate{}}

      iex> delete_youtube_video_translate(youtube_video_translate)
      {:error, %Ecto.Changeset{}}

  """
  def delete_youtube_video_translate(%YoutubeVideoTranslate{} = youtube_video_translate) do
    Repo.delete(youtube_video_translate)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking youtube_video_translate changes.

  ## Examples

      iex> change_youtube_video_translate(youtube_video_translate)
      %Ecto.Changeset{data: %YoutubeVideoTranslate{}}

  """
  def change_youtube_video_translate(
        %YoutubeVideoTranslate{} = youtube_video_translate,
        attrs \\ %{}
      ) do
    YoutubeVideoTranslate.changeset(youtube_video_translate, attrs)
  end
end
