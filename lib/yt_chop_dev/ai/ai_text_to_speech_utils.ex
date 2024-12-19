defmodule YtChopDev.AI.AITextToSpeechUtils do
  def text_to_speech(content, language \\ "vie", gender \\ "male") when is_binary(content) do
    key = Application.get_env(:yt_chop_dev, :tts_api_key)
    url = "https://texttospeech.googleapis.com/v1/text:synthesize" <> "?key=#{key}"

    voice =
      case {language, gender} do
        {"vie", "male"} -> %{languageCode: "vi-VN", name: "vi-VN-Neural2-D"}
        {"vie", "female"} -> %{languageCode: "vi-VN", name: "vi-VN-Neural2-A"}
        {"jap", "male"} -> %{languageCode: "ja-JP", name: "ja-JP-Neural2-C"}
        {"jap", "female"} -> %{languageCode: "ja-JP", name: "ja-JP-Neural2-B"}
        {"kor", "male"} -> %{languageCode: "ko-KR", name: "ko-KR-Neural2-C"}
        {"kor", "female"} -> %{languageCode: "ko-KR", name: "ko-KR-Neural2-A"}
      end

    body =
      %{
        input: %{text: content},
        voice: voice,
        audioConfig: %{audioEncoding: "LINEAR16"}
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"}
    ]

    case Req.post(url, body: body, headers: headers) do
      {:ok, %{status: 200, body: response_body}} ->
        bytes = Base.decode64!(response_body["audioContent"])
        {:ok, bytes}

      {:ok, %{status: status_code, body: response_body}} ->
        {:error,
         "Request failed with status code #{status_code}: #{Jason.encode!(response_body)}"}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end
end
