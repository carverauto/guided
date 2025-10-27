defmodule GuidedWeb.Admin.SecurityControlLive.Index do
  use GuidedWeb, :live_view

  alias Guided.Graph

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :security_controls, list_security_controls())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Security Control")
    |> assign(:security_control, get_security_control!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Security Control")
    |> assign(:security_control, %{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Security Controls")
    |> assign(:security_control, nil)
  end

  @impl true
  def handle_info({:put_flash, kind, msg}, socket) do
    {:noreply, put_flash(socket, kind, msg)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Graph.query("MATCH (n:SecurityControl) WHERE id(n) = #{id} DETACH DELETE n")

    {:noreply,
     socket
     |> put_flash(:info, "Security control deleted successfully")
     |> stream(:security_controls, list_security_controls(), reset: true)}
  end

  defp list_security_controls do
    case Graph.query("""
    MATCH (sc:SecurityControl)
    RETURN {id: id(sc), name: sc.name, category: sc.category, description: sc.description,
            implementation_difficulty: sc.implementation_difficulty}
    ORDER BY sc.name
    """) do
      {:ok, results} ->
        Enum.map(results || [], fn result ->
          %{
            id: result["id"] || 0,
            name: result["name"] || "",
            category: result["category"] || "",
            description: result["description"] || "",
            implementation_difficulty: result["implementation_difficulty"] || ""
          }
        end)
      {:error, _} -> []
    end
  end

  defp get_security_control!(id) do
    case Graph.query("""
    MATCH (sc:SecurityControl)
    WHERE id(sc) = #{id}
    RETURN {id: id(sc), name: sc.name, category: sc.category, description: sc.description,
            implementation_difficulty: sc.implementation_difficulty}
    """) do
      {:ok, [result]} ->
        %{
          id: result["id"] || String.to_integer("#{id}"),
          name: result["name"] || "",
          category: result["category"] || "",
          description: result["description"] || "",
          implementation_difficulty: result["implementation_difficulty"] || ""
        }
      {:error, _} ->
        %{
          id: String.to_integer("#{id}"),
          name: "",
          category: "",
          description: "",
          implementation_difficulty: ""
        }
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <.header>
        Security Controls
        <:subtitle>Manage security controls in the knowledge graph</:subtitle>
        <:actions>
          <.link navigate={~p"/admin"} class="text-sm font-semibold text-gray-600 hover:text-gray-900">
            ← Back to Dashboard
          </.link>
          <.link patch={~p"/admin/security_controls/new"}>
            <.button>New Security Control</.button>
          </.link>
        </:actions>
      </.header>

      <.table
        id="security_controls"
        rows={@streams.security_controls}
        row_click={fn {_id, control} -> JS.navigate(~p"/admin/security_controls/#{control.id}/edit") end}
      >
        <:col :let={{_id, control}} label="Name">{control.name}</:col>
        <:col :let={{_id, control}} label="Category">
          <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20">
            {control.category}
          </span>
        </:col>
        <:col :let={{_id, control}} label="Difficulty">
          <span class={"inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{difficulty_color(control.implementation_difficulty)}"}>
            {control.implementation_difficulty}
          </span>
        </:col>
        <:action :let={{_id, control}}>
          <.link patch={~p"/admin/security_controls/#{control.id}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, control}}>
          <.link
            phx-click={JS.push("delete", value: %{id: control.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="security-control-modal"
        show
        on_cancel={JS.patch(~p"/admin/security_controls")}
      >
        <.live_component
          module={GuidedWeb.Admin.SecurityControlLive.FormComponent}
          id={@security_control[:id] || :new}
          title={@page_title}
          action={@live_action}
          security_control={@security_control}
          patch={~p"/admin/security_controls"}
        />
      </.modal>
    </div>
    """
  end

  defp difficulty_color("low"), do: "bg-green-50 text-green-700 ring-1 ring-inset ring-green-600/20"
  defp difficulty_color("medium"), do: "bg-yellow-50 text-yellow-700 ring-1 ring-inset ring-yellow-600/20"
  defp difficulty_color("high"), do: "bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20"
  defp difficulty_color(_), do: "bg-gray-50 text-gray-700 ring-1 ring-inset ring-gray-600/20"
end
