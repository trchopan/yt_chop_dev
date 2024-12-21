defmodule YtChopDev.Helpers do
  # def split_timestamps(input) do
  #   input |> String.split("\n")
  # end

  def split_timestamps(input) do
    # Regular expression to match each "TIMESTAMP >>> TEXT" pattern
    regex = ~r/\d+\.\d+ >>>(?: [^\n]+)?(?:\n(?!\d+\.\d+ >>> )[^\n]+)*/

    # Scan input for the matches
    Regex.scan(regex, input)
    |> Enum.map(fn [match] -> String.trim(match) end)
  end

  def format_seconds(seconds) do
    m = div(seconds, 60)
    s = rem(seconds, 60)

    "#{m}:#{String.pad_leading(Integer.to_string(s), 2, "0")}"
  end
end
