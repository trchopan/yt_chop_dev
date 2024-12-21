defmodule YtChopDev.Recaptcha do
  def verify(token, action) do
    api_key = "AIzaSyD8k53WWi__MCv23f_OwFutdX0mPTBuqdY"

    Req.post(
      "https://recaptchaenterprise.googleapis.com/v1/projects/lina-tran/assessments?key=#{api_key}",
      json: %{
        event: %{
          token: token,
          expectedAction: action,
          siteKey: Application.get_env(:yt_chop_dev, :recaptcha_key)
        }
      }
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: body}} ->
        recaptcha_valid = body["tokenProperties"]["valid"]
        recaptcha_action = body["tokenProperties"]["action"]
        recaptcha_score = body["riskAnalysis"]["score"]

        valid = recaptcha_valid && recaptcha_action == action && recaptcha_score >= 0.7

        {:ok, valid}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, "HTTP request failed: #{Integer.to_string(status)} #{inspect(body)}"}

      {:error, exeption} ->
        {:error, "HTTP request failed: #{exeption.reason}"}
    end
  end
end
