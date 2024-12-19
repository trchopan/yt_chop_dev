defmodule YtChopDev.AI.AITextUtils do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI
  alias YtChopDev.DepsCustom.LangChain.ChatModels.ChatGoogleAICustom
  alias LangChain.Message

  @spec text_to_image_prompt(String.t()) :: {:ok, String.t()}
  def text_to_image_prompt(content) when is_binary(content) do
    messages = [
      Message.new_system!("""
      You are an expert in creating text-to-image prompts to convey the meaning of a content script. The resulting images will be used to visually represent the points in the script.

      The images should be in a cartoon style. Prefer to use visual and symbols to convey the meaning rather than text.

      Output the prompt to be used in the image generation model like Dall-E or Stable Diffusion. The prompt must be in english. Avoid prompts that contrast the content; instead, focus on illustrating the elements within the content.
      """),
      Message.new_user!("""
      SCRIPT:

      Trong một công ty tài chính, việc báo cáo tình hình thị trường, theo dõi các biến động, và tổng hợp thông tin về các danh mục tài chính của khách hàng thường rất tốn thời gian vì phải tự tổng hợp và viết lại nội dung, trau chuốt câu từ cho từng khách hàng hoặc từng ngành hàng.

      Chương trình mà nhóm mình phát triển thu thập thông tin từ các nguồn như tin tức tài chính, giá cổ phiếu, trái phiếu, các chỉ số index, Lịch kinh tế Mỹ, vv. 

      Sau đó sử dụng Generative AI để tạo ra các báo cáo tài chính theo các mẫu template do người dùng soạn sẵn, tự động hóa hoàn toàn các công đoạn thu thập thông tin để tạo ra báo cáo. Các chuyên gia tài chính chỉ cần kiểm tra và duyệt lại trước khi gửi cho khách hàng.
      """),
      Message.new_assistant!("""
      A cartoon depicting a busy financial office with employees overwhelmed by stacks of reports and market data displayed on multiple screens. In the foreground, a friendly robot using a laptop effortlessly generates financial reports. The robot gathers information symbolically from various sources like news icons, stock charts, bond symbols, index graphs, and a calendar with the USA flag. A pleased financial expert reviews and approves the reports prepared by the robot, ready to send them to clients.
      """),
      Message.new_user!("""
      SCRIPT:

      Human history is told by the energy we use. At first, we used our muscles; then, we learned to control fire. We industrialized the world using coal and oil and entered the Atomic Age when we learned to split a nucleus. At each step, we increased our energy harvest to a scale never before seen and advanced as a species. Currently, we are slowly transitioning to renewables, and if we are lucky, fusion energy will become viable in the future.
      """),
      Message.new_assistant!("""
      A cartoon timeline depicting the evolution of human energy usage. Start with an early human using muscles to lift something heavy, then show early humans gathered around a campfire. Next, illustrate the Industrial Revolution with factories billowing coal smoke and early automobiles powered by oil. Include a striking image of a nuclear power plant with atomic symbols to represent the Atomic Age. Finally, illustrate solar panels, wind turbines, and a futuristic fusion reactor, symbolizing the hope for future renewable energy sources. Use visual elements like caveman attire, steam engines, and futuristic cities to enhance the historical transition.
      """),
      Message.new_user!("SCRIPT:\n\n" <> content)
    ]

    run_messages(messages, :vertex_ai)
  end

  @spec format_text(String.t()) :: {:ok, String.t()}
  def format_text(content) when is_binary(content) do
    messages = [
      Message.new_system!("""
      Format the given content into Markdown text.

      Improve the text by adding correct punctuation, spelling, and grammar, but do not add or change the text content.

      Split the headers appropriately.
      """),
      Message.new_user!(content)
    ]

    run_messages(messages, :vertex_ai_flash)
  end

  def translate_text(content, target) when is_binary(content) do
    messages = [
      Message.new_system!("""
      Translate the given content to #{translate_target(target)}.
      """),
      Message.new_user!(content)
    ]

    run_messages(messages, :vertex_ai_flash)
  end

  defp translate_target("vie"), do: "Vietnamese"
  defp translate_target("jap"), do: "Japanese"
  defp translate_target("kor"), do: "Korean"

  @doc """
  Converts a given text content into Reveal.js slides in Markdown format.

  ## Parameters
  - `content` (String): The content script that needs to be illustrated.

  """
  @spec text_to_revealjs(String.t()) :: {:ok, String.t()}
  def text_to_revealjs(content) when is_binary(content) do
    messages = [
      Message.new_system!("""
      You are expert in making revealjs slides with markdown content. Your job is to use the given script to make the slides to illustrate the points in the content.

      Header of the slide(s) should start with level 4 (ie: #### Header).
      """),
      Message.new_user!("""
      SCRIPT:

      Ứng dụng mà team mình tham gia có tên là MarkGen.ai, một công cụ sử dụng công nghệ Generative AI để tự động hóa việc tạo báo cáo tài chính.

      Trong một công ty tài chính, việc báo cáo tình hình thị trường, theo dõi các biến động, và tổng hợp thông tin về các danh mục tài chính của khách hàng thường rất tốn thời gian vì phải tự tổng hợp và viết lại nội dung, trau chuốt câu từ cho từng khách hàng hoặc từng ngành hàng.
      """),
      Message.new_assistant!("""
      #### MarkGen.ai: Công cụ Tạo Báo Cáo Tài Chính Tự Động

      Sử dụng công nghệ Generative AI để tự động hóa việc tạo báo cáo tài chính.

      ---

      #### Thách Thức Trong Công Ty Tài Chính

      -   Báo cáo tình hình thị trường
      -   Theo dõi các biến động
      -   Tổng hợp thông tin về các danh mục tài chính của khách hàng

      Rất tốn thời gian

      ---

      #### Quy Trình Truyền Thống

      -   Tự tổng hợp và viết lại nội dung
      -   Trau chuốt câu từ cho từng khách hàng hoặc từng ngành hàng.

      ---
      """),
      Message.new_user!("SCRIPT:\n\n" <> content)
    ]

    run_messages(messages, :vertex_ai)
  end

  def transcript_translate(content, target) when is_binary(content) do
    example_output =
      case target do
        "vie" ->
          Message.new_system!("""
          0.16 >>> Hôm nay tôi đã đăng một dòng tweet, tôi nghĩ rằng, bạn biết đấy, đã đến lúc phải đầu tư.
          3.879 >>> Tôi nói có lẽ chỉ có mình tôi cảm thấy vậy, nhưng tôi cảm thấy thị trường cho các nhân vật nữ chính có ngoại hình nam tính, không hấp dẫn theo kiểu thông thường trong game không lớn như ngành công nghiệp video game nghĩ.
          13.44 >>> Và tôi đang nghĩ về nhân vật này, rõ ràng là tôi nghĩ đây giống như Intergalactic hay gì đó, trò chơi này có lẽ đã bắt đầu phát triển hơn 5 năm trước.
          22.96 >>> Và có thể khi đó, một nhân vật như thế này có vẻ như là một ý tưởng tốt hơn.
          26.96 >>> Đồ họa của game này thực sự rất tốt.
          29.519 >>> Nếu bạn không thích nhân vật, thì có rất nhiều tác phẩm nghệ thuật mà tôi không phải là fan, nhưng tôi vẫn có thể ngưỡng mộ vì nó trông rất đẹp.
          38.0 >>> Tôi nghĩ rằng, nếu bạn đang tìm kiếm một thợ săn tiền thưởng không gian mang phong cách retro những năm 80, những người chuyên săn tiền thưởng, bắn người và chiến đấu bằng kiếm laser, thì bạn đang nhắm đến một phần đông khán giả nam.
          """)

        "jap" ->
          Message.new_system!("""
          0.16 >>> 今日、私はツイートを投稿しました。皆さんもご存知のように、投資を始める時が来たのだと思いました。
          3.879 >>> 私はおそらく自分だけがそう感じているのかもしれないと言いましたが、ビデオゲーム業界が考えるほど、通常の魅力を持たない男性的な外見の女性主人公がいる市場は、それほど大きくないと感じています。
          13.44 >>> そして、このキャラクターについて考えていました。明らかに私が考えていたのは、インターギャラクティックか何かのようなもので、おそらくこのゲームは5年以上前から開発が始まったものだと思います。
          22.96 >>> そして、おそらくその時には、このようなキャラクターはより良いアイデアのように思えたのかもしれません。
          26.96 >>> このゲームのグラフィックスは本当に素晴らしいです。
          29.519 >>> キャラクターが好きでないなら、私がファンでない多くのアートもありますが、それでも非常に美しく見えるため鑑賞できます。
          38.0 >>> もしあなたが80年代風のレトロなスタイルの宇宙賞金稼ぎを探しているのなら、彼らは人を狙ったり、銃で撃ったり、レーザー剣で戦ったりする専門家で、その場合、あなたは主に男性のオーディエンスを狙っています。
          """)

        "kor" ->
          Message.new_system!("""
          0.16 >>> 오늘 저는 트윗을 올렸어요. 제 생각에는, 아시다시피, 이제는 투자할 때가 되었다고 생각했습니다.
          3.879 >>> 아마도 저 혼자만 그렇게 느낄 수 있지만, 저는 비디오 게임 산업이 생각하는 것만큼 게임 속에서 남성적인 외모와 일반적인 매력을 갖지 않은 여성 주인공 캐릭터에 대한 시장이 크지 않다고 느낍니다.
          13.44 >>> 그리고 저는 이 캐릭터에 대해 생각하고 있었고, 분명히 이게 우주적인 무언가와 비슷하다고 생각합니다. 이 게임은 아마도 5년 이상 전에 개발이 시작되었을 것입니다.
          22.96 >>> 아마도 그때는 이런 캐릭터가 더 좋은 아이디어처럼 보였을지도 모릅니다.
          26.96 >>> 이 게임의 그래픽은 정말 좋습니다.
          29.519 >>> 캐릭터가 마음에 들지 않더라도, 제가 팬이 아닌 많은 예술 작품들이 있지만, 그것이 매우 아름다워 보이기 때문에 여전히 감탄할 수 있습니다.
          38.0 >>> 80년대 레트로 스타일의 우주 현상금 사냥꾼, 즉 현상금을 사냥하고, 사람을 쏘고, 레이저 검으로 싸우는 사람을 찾고 있다면, 남성 관객의 상당 부분을 대상으로 하고 있다는 생각이 듭니다.
          """)

        _ ->
          raise "Invalid target"
      end

    messages = [
      Message.new_system!("""
      You are an expert in translating video scripts into text. The user will give you a script with timestamps for each line without any punctuation. Your task is to translate the script into proper punctuation and full sentences. You may combine multiple lines into a sentence and indicate the correct timestamps.

      Output the transcript translation to #{translate_target(target)} and keep the format of the transcript:
      TIMESTAMP >>> TRANSCRIPT 
      """),
      Message.new_user!("""
      0.16 >>> I made a tweet today I figured that you
      2.36 >>> know it's like it's time to make an
      3.879 >>> investment I said maybe it's just me but
      6.279 >>> I feel like the market for masculine
      8.639 >>> non-conventionally attractive female
      10.679 >>> leads in games isn't as big as the video
      13.44 >>> game industry thinks it is and I was
      15.4 >>> thinking about this character obviously
      17.32 >>> I think this like Intergalactic or
      18.96 >>> something like that this game probably
      20.68 >>> started development over 5 years ago and
      22.96 >>> like maybe back then a character like
      25.039 >>> this might have seemed like it was a
      26.96 >>> better idea the graphics for this are
      29.519 >>> really really good if you don't like the
      32.0 >>> character or whatever there are a lot of
      34.04 >>> paintings that I'm not a fan of but I
      35.84 >>> can admire that it looks really good I
      38.0 >>> think that if you are looking at a space
      40.8 >>> bounty hunter that has 80s retro
      43.68 >>> aesthetic that are about bounty hunting
      45.399 >>> and shooting people and fighting with
      46.68 >>> laser swords you are looking at a super
      49.48 >>> majority male audience
      """),
      example_output,
      Message.new_user!(content)
    ]

    run_messages(messages, :vertex_ai_flash)
  end

  @doc """
  Processes a list of messages using a specified Large Language Model (LLM) and handles the response.

  This function initializes a chat model using Vertex AI, adds messages to the model's processing chain, and executes the chain. The response from the model is then handled based on the specified LLM.

  ## Parameters

    - `messages`: A list of messages to be processed by the LLM. Each message should be in a format compatible with the LLMChain's `add_messages/2` function.
    - `llm`: An atom indicating the type of LLM to use for processing. Supported values are `:vertex_ai` and `:openai`.

  ## Returns

    - `{:ok, content}`: A tuple containing the atom `:ok` and the processed content from the last message in the chain. The content format may vary depending on the LLM used.

  ## Examples

    iex> run_messages([%{role: "user", content: "Hello, how are you?"}], :vertex_ai)
    {:ok, "I'm fine, thank you!"}

    iex> run_messages([%{role: "user", content: "Tell me a joke."}], :openai)
    {:ok, "Why did the chicken cross the road? To get to the other side!"}

  """
  def run_messages(messages, llm) do
    with {:ok, _messages, last_message} <-
           %{llm: get_llm(llm)}
           |> LLMChain.new!()
           |> LLMChain.add_messages(messages)
           |> LLMChain.run() do
      handle_response(last_message, llm)
    else
      {:error, _, detail} ->
        {:error, detail}
    end
  end

  def get_llm(:vertex_ai) do
    get_vertexai("gemini-1.5-pro-002")
  end

  def get_llm(:vertex_ai_flash) do
    get_vertexai("gemini-2.0-flash-exp")
  end

  def get_llm(:openai) do
    ChatOpenAI.new!(%{
      model: "gpt-4o",
      api_key: Application.get_env(:langchain, :openai_api_key),
      request_timeout: 60_000 * 2
    })
  end

  def split_prompt_by_newline(s),
    do:
      s
      |> String.split("\n")
      |> Enum.map(&String.trim(&1))
      |> Enum.filter(&(&1 != ""))

  defp handle_response(last_message, :vertex_ai),
    do: {:ok, last_message.content |> Enum.at(0) |> then(& &1.content)}

  defp handle_response(last_message, :vertex_ai_flash),
    do: {:ok, last_message.content |> Enum.at(0) |> then(& &1.content)}

  defp handle_response(last_message, :openai), do: {:ok, last_message.content}

  defp get_vertexai(model) do
    # LangChain.ChatModels.ChatGoogleAI
    ChatGoogleAICustom.new!(%{
      model: model,
      api_key: Application.get_env(:langchain, :vertex_ai_key),
      request_timeout: 60_000 * 2
    })
  end
end
