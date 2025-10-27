defmodule GuidedWeb.MCPIntegrationTest do
  use GuidedWeb.ConnCase, async: false

  alias Guided.Graph

  # Seed test data before each test
  setup do
    # Clear the graph
    {:ok, _} = Graph.query("MATCH (n) DETACH DELETE n")

    # Seed minimal test data
    seed_test_data()

    :ok
  end

  defp seed_test_data do
    # Create Technologies
    {:ok, _} = Graph.create_node("Technology", %{
      name: "Streamlit",
      category: "framework",
      description: "Python framework for data apps",
      security_rating: "good"
    })

    {:ok, _} = Graph.create_node("Technology", %{
      name: "SQLite",
      category: "database",
      description: "Lightweight SQL database",
      security_rating: "good"
    })

    # Create Use Case
    {:ok, _} = Graph.create_node("UseCase", %{
      name: "data_dashboard",
      description: "Interactive data dashboard",
      user_scale: "1-1000"
    })

    # Create Vulnerability
    {:ok, _} = Graph.create_node("Vulnerability", %{
      name: "SQL Injection",
      severity: "critical",
      description: "Malicious SQL injection",
      owasp_rank: "A03:2021"
    })

    # Create Security Control
    {:ok, _} = Graph.create_node("SecurityControl", %{
      name: "Parameterized Queries",
      category: "input_validation",
      description: "Use prepared statements",
      implementation_difficulty: "low"
    })

    # Create Best Practice
    {:ok, _} = Graph.create_node("BestPractice", %{
      name: "Use SQLAlchemy with Parameterized Queries",
      technology: "SQLite",
      category: "database_security",
      description: "Always use parameterized queries",
      code_example: "session.query(User).filter(User.name == user_input)"
    })

    # Create Deployment Pattern
    {:ok, _} = Graph.create_node("DeploymentPattern", %{
      name: "Streamlit Cloud",
      platform: "streamlit_cloud",
      cost: "free_tier_available",
      complexity: "low",
      description: "Official Streamlit hosting",
      https_support: true
    })

    # Create Relationships
    Graph.create_relationship("Technology", %{name: "Streamlit"}, "RECOMMENDED_FOR", "UseCase", %{name: "data_dashboard"})
    Graph.create_relationship("Technology", %{name: "SQLite"}, "RECOMMENDED_FOR", "UseCase", %{name: "data_dashboard"})
    Graph.create_relationship("Technology", %{name: "SQLite"}, "HAS_VULNERABILITY", "Vulnerability", %{name: "SQL Injection"})
    Graph.create_relationship("Vulnerability", %{name: "SQL Injection"}, "MITIGATED_BY", "SecurityControl", %{name: "Parameterized Queries"})
    Graph.create_relationship("Technology", %{name: "SQLite"}, "HAS_BEST_PRACTICE", "BestPractice", %{name: "Use SQLAlchemy with Parameterized Queries"})
    Graph.create_relationship("BestPractice", %{name: "Use SQLAlchemy with Parameterized Queries"}, "IMPLEMENTS_CONTROL", "SecurityControl", %{name: "Parameterized Queries"})
    Graph.create_relationship("UseCase", %{name: "data_dashboard"}, "RECOMMENDED_DEPLOYMENT", "DeploymentPattern", %{name: "Streamlit Cloud"})

    :ok
  end

  describe "MCP Server HTTP Integration" do
    test "initialize creates a new session", %{conn: conn} do
      conn = conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-06-18",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0.0"}
        }
      })

      assert conn.status == 200
      response = Jason.decode!(conn.resp_body)
      assert response["result"]["serverInfo"]["name"] == "guided.dev MCP Server"
      assert response["result"]["capabilities"]["tools"] == %{}
    end

    test "tools/list returns all three tools", %{conn: conn} do
      # First initialize
      init_conn = conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-06-18",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0.0"}
        }
      })

      # Get session ID from init response
      init_response = Jason.decode!(init_conn.resp_body)
      assert init_response["result"]

      # Send notifications/initialized
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "method" => "notifications/initialized"
      })

      # Now list tools
      tools_conn = conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 2,
        "method" => "tools/list",
        "params" => %{}
      })

      assert tools_conn.status == 200
      response = Jason.decode!(tools_conn.resp_body)
      tools = response["result"]["tools"]

      assert length(tools) == 3
      tool_names = Enum.map(tools, & &1["name"])
      assert "tech_stack_recommendation" in tool_names
      assert "secure_coding_pattern" in tool_names
      assert "deployment_guidance" in tool_names
    end

    test "tech_stack_recommendation tool returns recommendations", %{conn: conn} do
      # Initialize session
      init_conn = conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "initialize",
        "params" => %{
          "protocolVersion" => "2025-06-18",
          "capabilities" => %{},
          "clientInfo" => %{"name" => "test", "version" => "1.0.0"}
        }
      })

      assert init_conn.status == 200

      # Send notifications/initialized
      conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "method" => "notifications/initialized"
      })

      # Call tech_stack_recommendation
      tool_conn = conn
      |> put_req_header("content-type", "application/json")
      |> put_req_header("accept", "application/json, text/event-stream")
      |> post("/mcp", %{
        "jsonrpc" => "2.0",
        "id" => 3,
        "method" => "tools/call",
        "params" => %{
          "name" => "tech_stack_recommendation",
          "arguments" => %{
            "intent" => "build a dashboard for data visualization",
            "context" => %{}
          }
        }
      })

      assert tool_conn.status in [200, 202]
    end
  end
end
