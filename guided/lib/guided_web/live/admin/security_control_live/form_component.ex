defmodule GuidedWeb.Admin.SecurityControlLive.FormComponent do
  use GuidedWeb, :live_component

  alias Guided.Graph

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage security control records in the knowledge graph.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="security-control-form"
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
            {"Input Validation", "input_validation"},
            {"Output Handling", "output_handling"},
            {"Authentication", "authentication"},
            {"Authorization", "authorization"},
            {"Encryption", "encryption"},
            {"Logging & Monitoring", "logging_monitoring"}
          ]}
          required
        />
        <.input
          field={@form[:implementation_difficulty]}
          type="select"
          label="Implementation Difficulty"
          options={[
            {"Low", "low"},
            {"Medium", "medium"},
            {"High", "high"}
          ]}
        />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Security Control</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{security_control: security_control} = assigns, socket) do
    form_data = atomize_to_strings(security_control)

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
    save_security_control(socket, socket.assigns.action, params)
  end

  defp save_security_control(socket, :edit, params) do
    id = socket.assigns.security_control.id

    set_clauses =
      params
      |> Map.take(["name", "category", "description", "implementation_difficulty"])
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == "" end)
      |> Enum.map(fn {k, v} -> "sc.#{k} = '#{escape_string(v)}'" end)
      |> Enum.join(", ")

    query = """
    MATCH (sc:SecurityControl)
    WHERE id(sc) = #{id}
    SET #{set_clauses}
    RETURN id(sc)
    """

    case Graph.query(query) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Security control updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error updating security control")}
    end
  end

  defp save_security_control(socket, :new, params) do
    properties = %{
      name: params["name"],
      category: params["category"] || "input_validation",
      description: params["description"] || "",
      implementation_difficulty: params["implementation_difficulty"] || "medium"
    }

    case Graph.create_node("SecurityControl", properties) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Security control created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error creating security control")}
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
