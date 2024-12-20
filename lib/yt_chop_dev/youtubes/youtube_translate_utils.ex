defmodule YtChopDev.Youtubes.YoutubeTranslateUtils do
  require Logger
  alias YtChopDev.Youtubes.YoutubeVideoTranslate
  alias YtChopDev.Youtubes
  alias YtChopDev.Youtubes.YoutubeVideo
  alias YtChopDev.AI.AITextUtils
  alias YtChopDev.AI.AITextToSpeechUtils
  alias YtChopDev.Youtubes.YoutubeInfoUtils

  def download_transcript_html(youtube_url, opts \\ []) do
    Req.post("https://youtubetotranscript.com/transcript",
      headers: [
        {"accept",
         "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8"},
        {"accept-language", "en-US,en;q=0.6"},
        {"content-type", "application/x-www-form-urlencoded"}
      ],
      form: [youtube_url: youtube_url],
      receive_timeout: 30_000
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        if opts[:save] do
          File.write!("youtube-transcript.html", body)
        end

        {:ok, body}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end

  @doc """
  To use with download_transcript_html(url, save: true) to save to file and read from it without download it again
  """
  def parse_file_content(filter_sponsor \\ false) do
    file_content = File.read!("youtube-transcript.html")
    parse_transcript(file_content, filter_sponsor)
  end

  def parse_transcript(content, filter_sponsor \\ false) do
    {:ok, document} = Floki.parse_document(content)

    Floki.find(document, "#transcript > .text-primary-content")
    |> Enum.filter(fn {_tag, attrs, _children} ->
      data_tip = List.keyfind(attrs, "data-tip", 0)

      if data_tip == nil or filter_sponsor === false do
        true
      else
        data_tip_value = elem(data_tip, 1)
        data_tip_value !== "Sponsored Segment"
      end
    end)
    |> Enum.map(fn {_tag, _attrs, children} -> children end)
    |> List.flatten()
    |> Enum.filter(fn {_tag, _attrs, children} ->
      children |> Enum.join() |> String.trim() != ""
    end)
    |> Enum.map(fn {_tag, attrs, children} ->
      text = children |> Enum.join() |> String.replace(~r"\[.*?\]", "") |> String.trim()
      {data_start, _} = List.keyfind(attrs, "data-start", 0) |> elem(1) |> Float.parse()

      # TODO: add duration to data
      # {data_duration, _} = List.keyfind(attrs, "data-duration", 0) |> elem(1) |> Float.parse()

      {data_start, text}
    end)
    |> Enum.filter(fn {_start, text} ->
      text != ""
    end)
  end

  def translate_transcript(transcripts, language) do
    content =
      transcripts
      |> Enum.map(fn {data_start, text} ->
        "#{data_start} >>> #{text}"
      end)
      |> Enum.join("\n")

    with {:ok, result} <- AITextUtils.transcript_translate(content, language) do
      translated_transcripts =
        result
        |> String.split("\n")
        |> Enum.filter(&(String.trim(&1) != ""))
        |> Enum.map(fn s ->
          [timestamp, script] = String.split(s, ">>>") |> Enum.map(&String.trim(&1))
          {timestamp, _} = Float.parse(timestamp)
          {timestamp, script}
        end)

      {:ok, translated_transcripts}
    end
  end

  def transcript_to_audio(temp_dir, transcripts, language, gender) do
    audio_files =
      transcripts
      |> Enum.map(fn {timestamp, text} ->
        {:ok, audio_bytes} =
          AITextToSpeechUtils.text_to_speech(text, language, gender)

        filename = temp_dir <> "/" <> Float.to_string(timestamp) <> ".wav"

        with :ok <- File.write(filename, audio_bytes) do
          {:ok, filename}
        end
      end)

    if Enum.any?(audio_files, &match?({:error, _}, &1)) do
      {:error, audio_files |> Enum.filter(&match?({:error, _}, &1)) |> Enum.map(&elem(&1, 1))}
    else
      audio_files = audio_files |> Enum.map(&elem(&1, 1))
      concat_audio_files(temp_dir, audio_files)
    end
  end

  def get_media_length(path) do
    {output, _} =
      System.cmd(
        "ffprobe",
        ~w"-v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{path}"
      )

    {length, _} = Float.parse(output)
    length
  end

  def concat_audio_files(dir, files) do
    run_command(dir, "output_audio_translated.wav", fn output_path ->
      inputs =
        files
        |> Enum.map(fn file -> "file #{Path.basename(file)}" end)
        |> Enum.join("\n")

      input_txt = "#{dir}/inputs.txt"
      File.write!(input_txt, inputs)

      System.cmd(
        "ffmpeg",
        ~w"-y -hide_banner -v error -f concat -safe 0 -i #{input_txt} -c copy #{output_path}"
      )
    end)
  end

  def change_audio_tempo(dir, audio_path, tempo) when is_float(tempo) do
    run_command(dir, "output_audio_adjusted_tempo.wav", fn output_path ->
      System.cmd(
        "ffmpeg",
        ~w"-y -hide_banner -v error -i #{audio_path} -filter:a atempo=#{tempo} -vn #{output_path}"
      )
    end)
  end

  def audio_without_voice(dir, input_audio_path) do
    run_command(dir, "input_audio_remove_voice.wav", fn output_path ->
      System.cmd(
        "ffmpeg",
        ~w"-y -hide_banner -v error -i #{input_audio_path} -af pan=stereo|c0=c0|c1=-1*c1 -ac 1 #{output_path}"
      )
    end)
  end

  def combine_voice_sound(dir, voice_path, sound_path, offset) do
    run_command(dir, "output_audio.mp4", fn output_path ->
      offset_ms = (offset * 1000) |> Float.ceil() |> trunc()

      System.cmd(
        "ffmpeg",
        ~w"-y -hide_banner -v error -i #{sound_path} -i #{voice_path} -filter_complex [1]adelay=#{offset_ms}|#{offset_ms}[d1];[0][d1]amix=inputs=2:duration=longest #{output_path}"
      )
    end)
  end

  def combine_video_audio(dir, input_video_path, input_audio_path) do
    run_command(dir, "output.mp4", fn output_path ->
      System.cmd(
        "ffmpeg",
        ~w"-y -hide_banner -v error -i #{input_video_path} -i #{input_audio_path} -c:v copy -strict -2 #{output_path}"
      )
    end)
  end

  def youtube_translate(%YoutubeVideo{} = video, language, gender, force_translate \\ false) do
    youtube_id = video.video_id
    youtube_url = "https://www.youtube.com/watch?v=" <> youtube_id

    # Make the directories
    #
    persist_dir = "./youtube_downloads/" <> youtube_id
    File.mkdir_p!(persist_dir)
    temp_dir = persist_dir <> "/temp"
    File.mkdir_p!(temp_dir)
    output_dir = persist_dir <> "/#{language}/#{gender}"
    File.mkdir_p!(output_dir)

    # Main process
    #
    Logger.info("#{youtube_id} > Downloading video and audio")
    input_video_path = persist_dir <> "/input.mp4"
    input_audio_path = persist_dir <> "/input-audio.mp4"

    if !File.exists?(input_video_path) or !File.exists?(input_audio_path) do
      {:ok, video_info} = YoutubeInfoUtils.get_video_information(youtube_id)
      {:ok, video_url} = YoutubeInfoUtils.get_video_url(video_info)
      {:ok, input_video_binary} = YoutubeInfoUtils.download_binary(video_url)
      File.write!(input_video_path, input_video_binary)
      {:ok, audio_url} = YoutubeInfoUtils.get_audio_url(video_info)
      {:ok, input_audio_binary} = YoutubeInfoUtils.download_binary(audio_url)
      File.write!(input_audio_path, input_audio_binary)
    else
      Logger.info("#{youtube_id} > Video and audio already exists")
    end

    {video, transcripts} =
      if force_translate == false and video.transcript != nil do
        {video, video.transcript |> YoutubeVideo.transcript()}
      else
        Logger.info("#{youtube_id} > Downloading transcript")
        {:ok, transcript_file} = download_transcript_html(youtube_url)
        transcripts = parse_transcript(transcript_file)

        {:ok, video} =
          Youtubes.update_youtube_video(video, %{
            transcript: YoutubeVideo.to_transcript(transcripts)
          })

        {video, transcripts}
      end

    Logger.info(
      "#{youtube_id} > Transcript length #{String.length(inspect(transcripts, limit: :infinity))}"
    )

    Logger.info("#{youtube_id} > Creating translate for transcript")

    translate = Youtubes.get_youtube_video_translate_by_video_id(youtube_id, language, gender)

    {translate, translated_transcripts} =
      if force_translate == false and translate != nil do
        {translate, translate.transcript |> YoutubeVideoTranslate.transcript()}
      else
        Logger.info("#{youtube_id} > Translating transcript")

        if translate != nil do
          # TODO: Make upsert function instead of handle here
          # Remove old translate
          Youtubes.delete_youtube_video_translate(translate)
        end

        {:ok, translated_transcripts} = translate_transcript(transcripts, language)

        {:ok, translate} =
          Youtubes.create_youtube_video_translate_for_youtube_video(video, %{
            video_id: youtube_id,
            language: language,
            gender: gender,
            version: "1",
            transcript: YoutubeVideoTranslate.to_transcript(translated_transcripts)
          })

        {translate, translated_transcripts}
      end

    audio_offset = translated_transcripts |> Enum.at(0) |> elem(0)

    Logger.info("#{youtube_id} > Creating audio files for transcripts")
    {:ok, audio_path} = transcript_to_audio(temp_dir, translated_transcripts, language, gender)

    video_length = get_media_length(input_video_path)
    audio_length = get_media_length(audio_path)

    Logger.info(
      "#{youtube_id} > Video length: #{video_length}, Audio length: #{audio_length}, Offset: #{audio_offset}"
    )

    tempo = audio_length / (video_length - audio_offset)
    Logger.info("#{youtube_id} > Tempo: #{tempo}")

    {:ok, adjusted_tempo_audio_path} = change_audio_tempo(temp_dir, audio_path, tempo)

    Logger.info("#{youtube_id} > Making audio without voice #{input_audio_path}")
    {:ok, removed_voice_path} = audio_without_voice(temp_dir, input_audio_path)

    Logger.info(
      "#{youtube_id} > Combining voice and sound #{adjusted_tempo_audio_path} #{removed_voice_path} #{audio_offset}"
    )

    {:ok, final_input_audio_path} =
      combine_voice_sound(temp_dir, adjusted_tempo_audio_path, removed_voice_path, audio_offset)

    Logger.info(
      "#{youtube_id} > Combining video and audio #{input_video_path} #{final_input_audio_path}"
    )

    {:ok, output_path} =
      combine_video_audio(output_dir, input_video_path, final_input_audio_path)

    Logger.info("#{youtube_id} > Output path: #{output_path}")

    {:ok, translate} =
      Youtubes.update_youtube_video_translate(translate, %{
        public_url: output_path,
        filename: "#{youtube_id}/#{language}/#{gender}/#{Path.basename(output_path)}"
      })

    File.rm_rf!(temp_dir)

    {:ok, video, translate}
  end

  defp run_command(dir, output_file, cmd) do
    output_path = "#{dir}/#{output_file}"

    {_, exit_status} = cmd.(output_path)

    if exit_status != 0 do
      {:error, exit_status}
    else
      {:ok, output_path}
    end
  end
end
