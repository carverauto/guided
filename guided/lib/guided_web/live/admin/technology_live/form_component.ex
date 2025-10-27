defmodule GuidedWeb.Admin.TechnologyLive.FormComponent do
  use GuidedWeb, :live_component

  alias Guided.Graph

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage technology records in the knowledge graph.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="technology-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input
          field={@form[:category]}
          type="select"
          label="Category"
          options={[
            {"Language", "language"},
            {"Framework", "framework"},
            {"Database", "database"},
            {"Tool", "tool"},
            {"Library", "library"}
          ]}
          required
        />
        <.input field={@form[:version]} type="text" label="Version" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input
          field={@form[:maturity]}
          type="select"
          label="Maturity"
          options={[
            {"Mature", "mature"},
            {"Stable", "stable"},
            {"Beta", "beta"},
            {"Alpha", "alpha"},
            {"Experimental", "experimental"}
          ]}
        />
        <.input
          field={@form[:security_rating]}
          type="select"
          label="Security Rating"
          options={[
            {"Excellent", "excellent"},
            {"Good", "good"},
            {"Fair", "fair"},
            {"Poor", "poor"}
          ]}
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Technology</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{technology: technology} = assigns, socket) do
    # Convert atom keys to string keys for form compatibility
    form_data = atomize_to_strings(technology)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(to_form(form_data))}
  end

  @impl true
  def handle_event("validate", %{"name" => _name}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", params, socket) do
    save_technology(socket, socket.assigns.action, params)
  end

  defp save_technology(socket, :edit, params) do
    id = socket.assigns.technology.id

    # Build SET clause for all non-nil fields
    set_clauses =
      params
      |> Map.take(["name", "category", "version", "description", "maturity", "security_rating"])
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == "" end)
      |> Enum.map(fn {k, v} -> "t.#{k} = '#{escape_string(v)}'" end)
      |> Enum.join(", ")

    query = """
    MATCH (t:Technology)
    WHERE id(t) = #{id}
    SET #{set_clauses}
    RETURN id(t)
    """

    case Graph.query(query) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Technology updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error updating technology")}
    end
  end

  defp save_technology(socket, :new, params) do
    properties = %{
      name: params["name"],
      category: params["category"],
      version: params["version"] || "",
      description: params["description"] || "",
      maturity: params["maturity"] || "stable",
      security_rating: params["security_rating"] || "good"
    }

    case Graph.create_node("Technology", properties) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Technology created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error creating technology")}
    end
  end

  defp notify_parent(msg), do: send(self(), msg)

  defp escape_string(value) when is_binary(value) do
    String.replace(value, "'", "\\'")
  end

  defp escape_string(value), do: to_string(value)

  defp assign_form(socket, form) do
    assign(socket, :form, form)
  end

  defp atomize_to_strings(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
