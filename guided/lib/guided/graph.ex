defmodule Guided.Graph do
  @moduledoc """
  Graph query interface for executing openCypher queries against Apache AGE.

  This module provides an abstraction layer over the raw AGE queries,
  allowing the application to execute Cypher commands and parse results
  without directly handling SQL in business logic.
  """

  alias Guided.Repo
  import Ecto.Adapters.SQL, only: [query: 4]

  @graph_name "guided_graph"

  @doc """
  Executes an openCypher query against the graph database.

  ## Parameters

    - cypher: The openCypher query string
    - params: Optional list of parameters for the query (default: [])

  ## Returns

    - `{:ok, result}` on success with the query result
    - `{:error, reason}` on failure

  ## Examples

      iex> Guided.Graph.cypher("MATCH (n) RETURN n LIMIT 5")
      {:ok, %Postgrex.Result{rows: [...]}}

      iex> Guided.Graph.cypher("MATCH (n:Technology {name: $name}) RETURN n", ["Python"])
      {:ok, %Postgrex.Result{rows: [...]}}
  """
  def cypher(cypher_query, params \\ []) do
    # Load the AGE extension (must be separate query)
    with {:ok, _} <- query(Repo, "LOAD 'age'", [], []),
         {:ok, _} <- query(Repo, "SET search_path = ag_catalog, \"$user\", public", [], []) do
      # Build the Cypher query using AGE's cypher function
      # Convert agtype to text which Postgrex can handle
      if params == [] do
        sql_query = """
        SELECT ag_catalog.agtype_to_text(result) as result
        FROM ag_catalog.cypher('#{@graph_name}', $$#{cypher_query}$$) as (result ag_catalog.agtype)
        """
        query(Repo, sql_query, [], [])
      else
        # Convert params to AGE's agtype JSON format
        params_json = Jason.encode!(params |> Enum.with_index() |> Map.new(fn {v, i} -> {"$#{i}", v} end))
        sql_query = """
        SELECT ag_catalog.agtype_to_text(result) as result
        FROM ag_catalog.cypher($1, $2, $3) as (result ag_catalog.agtype)
        """
        query(Repo, sql_query, [@graph_name, cypher_query, params_json], [])
      end

    else
      {:error, error} -> {:error, error}
    end
  end

  @doc """
  Executes an openCypher query and returns the parsed results as Elixir data structures.

  This function automatically parses AGE's agtype format into native Elixir types.

  ## Examples

      iex> Guided.Graph.query("MATCH (n:Technology) RETURN n.name as name")
      {:ok, [%{"name" => "Python"}, %{"name" => "Streamlit"}]}
  """
  def query(cypher_query, params \\ []) do
    case cypher(cypher_query, params) do
      {:ok, result} ->
        parsed_rows = parse_agtype_results(result.rows)
        {:ok, parsed_rows}

      {:error, error} ->
        {:error, error}
    end
  end

  # Parses AGE agtype results (converted to text) into Elixir data structures.
  #
  # We use agtype_to_text() which returns a text representation.
  # This function parses them to native Elixir maps and lists.
  defp parse_agtype_results(rows) do
    Enum.map(rows, fn [text_value] ->
      # Text values from agtype_to_text are JSON-like strings
      # Try to parse as JSON first
      case Jason.decode(text_value) do
        {:ok, parsed} ->
          parsed
        {:error, _} ->
          # If it's not JSON, it might be a simple scalar value
          # Try to convert to appropriate type
          cond do
            text_value == "true" -> true
            text_value == "false" -> false
            text_value == "null" -> nil
            true ->
              # Try to parse as integer or float
              case Integer.parse(text_value) do
                {int, ""} -> int
                _ ->
                  case Float.parse(text_value) do
                    {float, ""} -> float
                    _ -> text_value
                  end
              end
          end
      end
    end)
  end

  @doc """
  Creates a node in the graph.

  ## Parameters

    - label: The node label (e.g., "Technology", "Vulnerability")
    - properties: A map of properties for the node

  ## Examples

      iex> Guided.Graph.create_node("Technology", %{name: "Python", version: "3.11"})
      {:ok, [%{"id" => ...}]}
  """
  def create_node(label, properties) do
    props_str = properties
                |> Enum.map(fn {k, v} -> "#{k}: '#{escape_string(v)}'" end)
                |> Enum.join(", ")

    # Return the id() of the created node instead of the full vertex
    # id() returns an integer which agtype_to_text can handle
    cypher_query = "CREATE (n:#{label} {#{props_str}}) RETURN id(n) as id"
    query(cypher_query)
  end

  @doc """
  Creates a relationship between two nodes.

  ## Parameters

    - from_label: Label of the source node
    - from_props: Properties to match the source node
    - rel_type: Relationship type (e.g., "RECOMMENDED_FOR", "MITIGATED_BY")
    - to_label: Label of the target node
    - to_props: Properties to match the target node
    - rel_props: Properties for the relationship (optional)

  ## Examples

      iex> Guided.Graph.create_relationship(
      ...>   "Vulnerability", %{name: "SQL Injection"},
      ...>   "MITIGATED_BY",
      ...>   "SecurityControl", %{name: "Parameterized Queries"},
      ...>   %{}
      ...> )
      {:ok, result}
  """
  def create_relationship(from_label, from_props, rel_type, to_label, to_props, rel_props \\ %{}) do
    from_match = build_property_match(from_props)
    to_match = build_property_match(to_props)
    rel_props_str = build_property_string(rel_props)

    cypher_query = """
    MATCH (a:#{from_label} #{from_match}), (b:#{to_label} #{to_match})
    CREATE (a)-[r:#{rel_type} #{rel_props_str}]->(b)
    RETURN id(r) as id
    """

    query(cypher_query)
  end

  @doc """
  Finds nodes by label and optional property filters.

  ## Examples

      iex> Guided.Graph.find_nodes("Technology", %{name: "Python"})
      {:ok, [%{"name" => "Python", ...}]}
  """
  def find_nodes(label, properties \\ %{}) do
    match = if map_size(properties) == 0 do
      ""
    else
      build_property_match(properties)
    end

    cypher_query = "MATCH (n:#{label} #{match}) RETURN n"
    query(cypher_query)
  end

  # Helper function to build property match strings for Cypher
  defp build_property_match(properties) when map_size(properties) == 0, do: ""
  defp build_property_match(properties) do
    props_str = properties
                |> Enum.map(fn {k, v} -> "#{k}: '#{escape_string(v)}'" end)
                |> Enum.join(", ")

    "{#{props_str}}"
  end

  # Helper function to build property strings for relationships
  defp build_property_string(properties) when map_size(properties) == 0, do: ""
  defp build_property_string(properties) do
    props_str = properties
                |> Enum.map(fn {k, v} -> "#{k}: '#{escape_string(v)}'" end)
                |> Enum.join(", ")

    "{#{props_str}}"
  end

  # Escape single quotes in strings for Cypher queries
  defp escape_string(value) when is_binary(value) do
    String.replace(value, "'", "\\'")
  end
  defp escape_string(value), do: to_string(value)
end
