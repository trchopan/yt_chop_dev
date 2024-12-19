defmodule TimestampSplitter do
  def split_timestamps(input) do
    # Regular expression to match each "TIMESTAMP >>> TEXT" pattern
    regex = ~r/\d+\.\d+ >>> [^\n]+(?:\n(?!\d+\.\d+ >>> )[^\n]+)*/

    # Scan input for the matches
    Regex.scan(regex, input)
    |> Enum.map(fn [match] -> String.trim(match) end)
  end
end
