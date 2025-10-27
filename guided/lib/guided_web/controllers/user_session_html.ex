defmodule GuidedWeb.UserSessionHTML do
  use GuidedWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:guided, Guided.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
