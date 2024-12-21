defmodule YtChopDev.Youtubes.YoutubeTranslateUtils do
  require Logger
  alias YtChopDev.Youtubes.YoutubeVideoTranslate
  alias YtChopDev.Youtubes
  alias YtChopDev.Youtubes.YoutubeVideo
  alias YtChopDev.AI.AITextUtils
  alias YtChopDev.AI.AITextToSpeechUtils
  alias YtChopDev.Youtubes.YoutubeInfoUtils

  def download_youtubetotranscript_html(youtube_url, opts \\ []) do
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

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "HTTP request failed: #{Integer.to_string(status)} #{inspect(body)}"}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end

  def parse_youtubetotranscript_html_content(content, filter_sponsor \\ false) do
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
      {data_start, text}
    end)
    |> Enum.filter(fn {_start, text} -> text != "" end)
  end

  @doc """
  To use with download_youtubetotranscript_html(url, save: true) to save to file and read from it without download it again
  """
  def parse_file_content(filter_sponsor \\ false) do
    file_content = File.read!("youtube-transcript.html")
    parse_youtubetotranscript_html_content(file_content, filter_sponsor)
  end

  def get_transcript_youtubetotranscript(youtube_url, filter_sponsor \\ false) do
    with {:ok, transcript_file} <- download_youtubetotranscript_html(youtube_url) do
      {:ok, parse_youtubetotranscript_html_content(transcript_file, filter_sponsor)}
    else
      {:error, detail} ->
        {:error, detail}
    end
  end

  def get_transcript_tactiq(youtube_url) do
    Req.post("https://tactiq-apps-prod.tactiq.io/transcript",
      headers: [
        {"Accept", "*/*"},
        {"Accept-Language", "en-US,en;q=0.6"},
        {"Cache-Control", "no-cache"},
        {"Connection", "keep-alive"},
        {"DNT", "1"},
        {"Origin", "https://tactiq.io"},
        {"Pragma", "no-cache"},
        {"Referer", "https://tactiq.io/"},
        {"Sec-Fetch-Dest", "empty"},
        {"Sec-Fetch-Mode", "cors"},
        {"Sec-Fetch-Site", "same-site"},
        {"Sec-GPC", "1"},
        {"User-Agent",
         "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"},
        {"content-type", "application/json"},
        {"sec-ch-ua", "\"Brave\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\""},
        {"sec-ch-ua-mobile", "?0"},
        {"sec-ch-ua-platform", "\"macOS\""}
      ],
      json: %{
        "videoUrl" => youtube_url,
        "langCode" => "en"
      }
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        captions =
          body["captions"]
          |> Enum.map(fn caption ->
            {start, _} = Float.parse(caption["start"])
            {start, caption["text"]}
          end)

        {:ok, captions}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "HTTP request failed: #{Integer.to_string(status)} #{inspect(body)}"}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end

  @doc """
  Get the transcript from multiple sources
  - youtubetotranscript
  - tactiq
  """
  def get_transcript(youtube_url) do
    operations = [
      &get_transcript_youtubetotranscript/1,
      &get_transcript_tactiq/1
    ]

    result =
      operations
      |> Enum.find_value(fn operation ->
        case operation.(youtube_url) do
          {:ok, result} ->
            result

          {:error, detail} ->
            Logger.error("get_transcript > #{inspect(detail)}")
            nil
        end
      end)

    if result == nil do
      {:error, "No transcript found"}
    else
      {:ok, result}
    end
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

  def transcript_to_tts(dir, transcripts, language, gender) do
    audio_files =
      transcripts
      |> Enum.with_index()
      |> Enum.map(fn {{timestamp, text}, index} ->
        {:ok, audio_bytes} =
          AITextToSpeechUtils.text_to_speech(text, language, gender)

        filename = dir <> "/" <> Float.to_string(timestamp) <> ".wav"

        with :ok <- File.write(filename, audio_bytes) do
          audio_length = get_media_length(filename)

          next_timestamp =
            transcripts
            |> Enum.at(index + 1)
            |> case do
              nil -> 0
              {ts, _} -> ts
            end

          should_be_audio_length = next_timestamp - timestamp

          {:ok, filename} =
            if should_be_audio_length > 0 and should_be_audio_length < audio_length do
              tempo = audio_length / should_be_audio_length

              tempo = if tempo > 1.2, do: 1.2, else: tempo

              new_filename = (filename |> Path.rootname() |> Path.basename()) <> "_tempo.wav"
              change_audio_tempo(dir, new_filename, filename, tempo)
            else
              {:ok, filename}
            end

          {:ok, {timestamp, filename}}
        end
      end)

    if Enum.any?(audio_files, &match?({:error, _}, &1)) do
      {:error, audio_files |> Enum.filter(&match?({:error, _}, &1)) |> Enum.map(&elem(&1, 1))}
    else
      {:ok, audio_files |> Enum.map(&elem(&1, 1))}
      # concat_audio_files(dir, audio_files)
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

  def change_audio_tempo(dir, output_name, audio_path, tempo) when is_float(tempo) do
    run_command(dir, output_name, fn output_path ->
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

  def combine_voice_sound_v2(dir, tts_audios, background_audio) do
    run_command(dir, "output_audio.wav", fn output_path ->
      # Prepare the input files part of the command
      input_files =
        tts_audios
        |> Enum.map(fn {_timestamp, filename} -> "-i #{filename}" end)
        |> Enum.join(" ")

      # Prepare the filter_complex part of the command
      filter_complex =
        tts_audios
        |> Enum.with_index(1)
        |> Enum.map(fn {{timestamp, _filename}, index} ->
          timestamp_ms = (timestamp * 1000) |> trunc()
          "[#{index}]adelay=delays=#{timestamp_ms}:all=1[r#{index}]"
        end)
        |> Enum.join("; ")

      # Prepare the amix part of the command
      amix_inputs = Enum.count(tts_audios) + 1

      amix =
        "[0]" <>
          Enum.map_join(1..Enum.count(tts_audios), "", fn i -> "[r#{i}]" end) <>
          "amix=inputs=#{amix_inputs}:dropout_transition=0,volume=4[out]"

      # Construct the full command
      command = """
      ffmpeg -y -hide_banner -v error \
      -i #{background_audio} \
      #{input_files} \
      -filter_complex "#{filter_complex}; #{amix}" \
      -map "[out]" \
      -codec:v copy #{output_path}
      """

      System.cmd("sh", ["-c", command])
    end)
  end

  def normalize_audio_volume(dir, audio_path) do
    run_command(dir, "output_norm.wav", fn output_path ->
      # ffmpeg -i output_audio.wav -filter:a "dynaudnorm=p=0.9:s=5,volume=2" output_norm.wav

      System.cmd("sh", [
        "-c",
        "ffmpeg -y -hide_banner -v error -i #{audio_path} -filter:a \"dynaudnorm=p=0.9:s=5,volume=1.2\" #{output_path}"
      ])
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

  def youtube_translate(%YoutubeVideo{} = video, language, gender, opts) do
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

    Logger.info("#{youtube_id} > Getting transcript")

    {video, transcripts} =
      if opts[:force_transcript] == true or video.transcript == nil do
        {:ok, transcripts} = get_transcript(youtube_url)

        {:ok, video} =
          Youtubes.update_youtube_video(video, %{
            transcript: YoutubeVideo.to_transcript(transcripts)
          })

        {video, transcripts}
      else
        Logger.info("#{youtube_id} > Found existing transcript")
        {video, video.transcript |> YoutubeVideo.transcript()}
      end

    Logger.info(
      "#{youtube_id} > Transcript length #{String.length(inspect(transcripts, limit: :infinity))}"
    )

    Logger.info("#{youtube_id} > Getting translation")
    translate = Youtubes.get_youtube_video_translate_by_video_id(youtube_id, language, gender)

    {translate, translated_transcripts} =
      if opts[:force_translate] == true or translate == nil do
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
      else
        Logger.info("#{youtube_id} > Found existing translation")
        {translate, translate.transcript |> YoutubeVideoTranslate.transcript()}
      end

    Logger.info("#{youtube_id} > Creating audio files for transcripts")
    {:ok, tts_audios} = transcript_to_tts(temp_dir, translated_transcripts, language, gender)

    Logger.info("#{youtube_id} > Making audio without voice #{input_audio_path}")
    {:ok, background_audio} = audio_without_voice(temp_dir, input_audio_path)

    Logger.info("#{youtube_id} > Combining voice and sound")

    {:ok, output_audio_path} =
      combine_voice_sound_v2(temp_dir, tts_audios, background_audio)

    {:ok, output_audio_path} = normalize_audio_volume(temp_dir, output_audio_path)

    Logger.info(
      "#{youtube_id} > Combining video and audio #{input_video_path} #{output_audio_path}"
    )

    {:ok, output_path} =
      combine_video_audio(output_dir, input_video_path, output_audio_path)

    Logger.info("#{youtube_id} > Output path: #{output_path}")

    {:ok, translate} =
      Youtubes.update_youtube_video_translate(translate, %{
        public_url: output_path,
        filename: "#{youtube_id}/#{language}/#{gender}/#{Path.basename(output_path)}"
      })

    if opts[:cleanup] == true do
      File.rm_rf!(temp_dir)
    end

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
