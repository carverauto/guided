defmodule GuidedWeb.Admin.BestPracticeLive.FormComponent do
  use GuidedWeb, :live_component

  alias Guided.Graph

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage best practice records in the knowledge graph.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="best-practice-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" required />
        <.input field={@form[:technology]} type="text" label="Technology" placeholder="e.g., Python, Streamlit" />
        <.input
          field={@form[:category]}
          type="select"
          label="Category"
          options={[
            {"Database Security", "database_security"},
            {"Input Validation", "input_validation"},
            {"Output Handling", "output_handling"},
            {"Configuration", "configuration"},
            {"Security Config", "security_config"},
            {"Authentication", "authentication"},
            {"Error Handling", "error_handling"}
          ]}
          required
        />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:code_example]} type="textarea" label="Code Example" placeholder="Example code snippet..." />
        <:actions>
          <.button phx-disable-with="Saving...">Save Best Practice</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{best_practice: best_practice} = assigns, socket) do
    form_data = atomize_to_strings(best_practice)

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
    save_best_practice(socket, socket.assigns.action, params)
  end

  defp save_best_practice(socket, :edit, params) do
    id = socket.assigns.best_practice.id

    set_clauses =
      params
      |> Map.take(["name", "technology", "category", "description", "code_example"])
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == "" end)
      |> Enum.map(fn {k, v} -> "bp.#{k} = '#{escape_string(v)}'" end)
      |> Enum.join(", ")

    query = """
    MATCH (bp:BestPractice)
    WHERE id(bp) = #{id}
    SET #{set_clauses}
    RETURN id(bp)
    """

    case Graph.query(query) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Best practice updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error updating best practice")}
    end
  end

  defp save_best_practice(socket, :new, params) do
    properties = %{
      name: params["name"],
      technology: params["technology"] || "",
      category: params["category"] || "general",
      description: params["description"] || "",
      code_example: params["code_example"] || ""
    }

    case Graph.create_node("BestPractice", properties) do
      {:ok, _} ->
        notify_parent({:saved, params})

        {:noreply,
         socket
         |> put_flash(:info, "Best practice created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Error creating best practice")}
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
