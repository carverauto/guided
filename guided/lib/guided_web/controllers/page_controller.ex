defmodule GuidedWeb.PageController do
  use GuidedWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
