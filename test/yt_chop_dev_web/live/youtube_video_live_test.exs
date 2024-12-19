defmodule YtChopDevWeb.YoutubeVideoLiveTest do
  use YtChopDevWeb.ConnCase

  import Phoenix.LiveViewTest
  import YtChopDev.YoutubesFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_youtube_video(_) do
    youtube_video = youtube_video_fixture()
    %{youtube_video: youtube_video}
  end

  describe "Index" do
    setup [:create_youtube_video]

    test "lists all youtube_videos", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/youtube_videos")

      assert html =~ "Listing Youtube videos"
    end

    test "saves new youtube_video", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/youtube_videos")

      assert index_live |> element("a", "New Youtube video") |> render_click() =~
               "New Youtube video"

      assert_patch(index_live, ~p"/youtube_videos/new")

      assert index_live
             |> form("#youtube_video-form", youtube_video: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#youtube_video-form", youtube_video: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/youtube_videos")

      html = render(index_live)
      assert html =~ "Youtube video created successfully"
    end

    test "updates youtube_video in listing", %{conn: conn, youtube_video: youtube_video} do
      {:ok, index_live, _html} = live(conn, ~p"/youtube_videos")

      assert index_live |> element("#youtube_videos-#{youtube_video.id} a", "Edit") |> render_click() =~
               "Edit Youtube video"

      assert_patch(index_live, ~p"/youtube_videos/#{youtube_video}/edit")

      assert index_live
             |> form("#youtube_video-form", youtube_video: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#youtube_video-form", youtube_video: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/youtube_videos")

      html = render(index_live)
      assert html =~ "Youtube video updated successfully"
    end

    test "deletes youtube_video in listing", %{conn: conn, youtube_video: youtube_video} do
      {:ok, index_live, _html} = live(conn, ~p"/youtube_videos")

      assert index_live |> element("#youtube_videos-#{youtube_video.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#youtube_videos-#{youtube_video.id}")
    end
  end

  describe "Show" do
    setup [:create_youtube_video]

    test "displays youtube_video", %{conn: conn, youtube_video: youtube_video} do
      {:ok, _show_live, html} = live(conn, ~p"/youtube_videos/#{youtube_video}")

      assert html =~ "Show Youtube video"
    end

    test "updates youtube_video within modal", %{conn: conn, youtube_video: youtube_video} do
      {:ok, show_live, _html} = live(conn, ~p"/youtube_videos/#{youtube_video}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Youtube video"

      assert_patch(show_live, ~p"/youtube_videos/#{youtube_video}/show/edit")

      assert show_live
             |> form("#youtube_video-form", youtube_video: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#youtube_video-form", youtube_video: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/youtube_videos/#{youtube_video}")

      html = render(show_live)
      assert html =~ "Youtube video updated successfully"
    end
  end
end
