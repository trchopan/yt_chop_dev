defmodule YtChopDev.YoutubesTest do
  use YtChopDev.DataCase

  alias YtChopDev.Youtubes

  describe "youtube_videos" do
    alias YtChopDev.Youtubes.YoutubeVideo

    import YtChopDev.YoutubesFixtures

    @invalid_attrs %{description: nil, author: nil, video_id: nil, thumbnail: nil, transcript: nil}

    test "list_youtube_videos/0 returns all youtube_videos" do
      youtube_video = youtube_video_fixture()
      assert Youtubes.list_youtube_videos() == [youtube_video]
    end

    test "get_youtube_video!/1 returns the youtube_video with given id" do
      youtube_video = youtube_video_fixture()
      assert Youtubes.get_youtube_video!(youtube_video.id) == youtube_video
    end

    test "create_youtube_video/1 with valid data creates a youtube_video" do
      valid_attrs = %{description: "some description", author: "some author", video_id: "some video_id", thumbnail: "some thumbnail", transcript: "some transcript"}

      assert {:ok, %YoutubeVideo{} = youtube_video} = Youtubes.create_youtube_video(valid_attrs)
      assert youtube_video.description == "some description"
      assert youtube_video.author == "some author"
      assert youtube_video.video_id == "some video_id"
      assert youtube_video.thumbnail == "some thumbnail"
      assert youtube_video.transcript == "some transcript"
    end

    test "create_youtube_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Youtubes.create_youtube_video(@invalid_attrs)
    end

    test "update_youtube_video/2 with valid data updates the youtube_video" do
      youtube_video = youtube_video_fixture()
      update_attrs = %{description: "some updated description", author: "some updated author", video_id: "some updated video_id", thumbnail: "some updated thumbnail", transcript: "some updated transcript"}

      assert {:ok, %YoutubeVideo{} = youtube_video} = Youtubes.update_youtube_video(youtube_video, update_attrs)
      assert youtube_video.description == "some updated description"
      assert youtube_video.author == "some updated author"
      assert youtube_video.video_id == "some updated video_id"
      assert youtube_video.thumbnail == "some updated thumbnail"
      assert youtube_video.transcript == "some updated transcript"
    end

    test "update_youtube_video/2 with invalid data returns error changeset" do
      youtube_video = youtube_video_fixture()
      assert {:error, %Ecto.Changeset{}} = Youtubes.update_youtube_video(youtube_video, @invalid_attrs)
      assert youtube_video == Youtubes.get_youtube_video!(youtube_video.id)
    end

    test "delete_youtube_video/1 deletes the youtube_video" do
      youtube_video = youtube_video_fixture()
      assert {:ok, %YoutubeVideo{}} = Youtubes.delete_youtube_video(youtube_video)
      assert_raise Ecto.NoResultsError, fn -> Youtubes.get_youtube_video!(youtube_video.id) end
    end

    test "change_youtube_video/1 returns a youtube_video changeset" do
      youtube_video = youtube_video_fixture()
      assert %Ecto.Changeset{} = Youtubes.change_youtube_video(youtube_video)
    end
  end

  describe "youtube_video_translates" do
    alias YtChopDev.Youtubes.YoutubeVideoTranslate

    import YtChopDev.YoutubesFixtures

    @invalid_attrs %{version: nil, filename: nil, language: nil, video_id: nil, public_url: nil, gender: nil}

    test "list_youtube_video_translates/0 returns all youtube_video_translates" do
      youtube_video_translate = youtube_video_translate_fixture()
      assert Youtubes.list_youtube_video_translates() == [youtube_video_translate]
    end

    test "get_youtube_video_translate!/1 returns the youtube_video_translate with given id" do
      youtube_video_translate = youtube_video_translate_fixture()
      assert Youtubes.get_youtube_video_translate!(youtube_video_translate.id) == youtube_video_translate
    end

    test "create_youtube_video_translate/1 with valid data creates a youtube_video_translate" do
      valid_attrs = %{version: "some version", filename: "some filename", language: "some language", video_id: "some video_id", public_url: "some public_url", gender: "some gender"}

      assert {:ok, %YoutubeVideoTranslate{} = youtube_video_translate} = Youtubes.create_youtube_video_translate(valid_attrs)
      assert youtube_video_translate.version == "some version"
      assert youtube_video_translate.filename == "some filename"
      assert youtube_video_translate.language == "some language"
      assert youtube_video_translate.video_id == "some video_id"
      assert youtube_video_translate.public_url == "some public_url"
      assert youtube_video_translate.gender == "some gender"
    end

    test "create_youtube_video_translate/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Youtubes.create_youtube_video_translate(@invalid_attrs)
    end

    test "update_youtube_video_translate/2 with valid data updates the youtube_video_translate" do
      youtube_video_translate = youtube_video_translate_fixture()
      update_attrs = %{version: "some updated version", filename: "some updated filename", language: "some updated language", video_id: "some updated video_id", public_url: "some updated public_url", gender: "some updated gender"}

      assert {:ok, %YoutubeVideoTranslate{} = youtube_video_translate} = Youtubes.update_youtube_video_translate(youtube_video_translate, update_attrs)
      assert youtube_video_translate.version == "some updated version"
      assert youtube_video_translate.filename == "some updated filename"
      assert youtube_video_translate.language == "some updated language"
      assert youtube_video_translate.video_id == "some updated video_id"
      assert youtube_video_translate.public_url == "some updated public_url"
      assert youtube_video_translate.gender == "some updated gender"
    end

    test "update_youtube_video_translate/2 with invalid data returns error changeset" do
      youtube_video_translate = youtube_video_translate_fixture()
      assert {:error, %Ecto.Changeset{}} = Youtubes.update_youtube_video_translate(youtube_video_translate, @invalid_attrs)
      assert youtube_video_translate == Youtubes.get_youtube_video_translate!(youtube_video_translate.id)
    end

    test "delete_youtube_video_translate/1 deletes the youtube_video_translate" do
      youtube_video_translate = youtube_video_translate_fixture()
      assert {:ok, %YoutubeVideoTranslate{}} = Youtubes.delete_youtube_video_translate(youtube_video_translate)
      assert_raise Ecto.NoResultsError, fn -> Youtubes.get_youtube_video_translate!(youtube_video_translate.id) end
    end

    test "change_youtube_video_translate/1 returns a youtube_video_translate changeset" do
      youtube_video_translate = youtube_video_translate_fixture()
      assert %Ecto.Changeset{} = Youtubes.change_youtube_video_translate(youtube_video_translate)
    end
  end
end
