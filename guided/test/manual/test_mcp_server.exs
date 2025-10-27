#!/usr/bin/env elixir

# Manual functional test for MCP server
# Run with: mix run test/manual/test_mcp_server.exs
#
# This test verifies the MCP server Cypher queries work correctly
# in the development environment where Apache AGE is available.

alias Guided.Graph

IO.puts("\n=== MCP Server Functional Test ===\n")

# Test 1: tech_stack_recommendation query
IO.puts("Test 1: tech_stack_recommendation Cypher query")
IO.puts("Testing positional parameter with data_dashboard use case...")

cypher_query = """
MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)
WHERE uc.name = $0
OPTIONAL MATCH (t)-[:HAS_VULNERABILITY]->(v:Vulnerability)
OPTIONAL MATCH (v)-[:MITIGATED_BY]->(sc:SecurityControl)
RETURN t.name as technology,
       t.category as category,
       t.description as description,
       t.security_rating as security_rating,
       v.name as vuln_name,
       v.severity as vuln_severity,
       v.description as vuln_description,
       sc.name as mitigation_name
"""

case Graph.query(cypher_query, ["data_dashboard"]) do
  {:ok, results} ->
    IO.puts("✓ Query succeeded")
    IO.puts("  Found #{length(results)} result rows")
    if length(results) > 0 do
      first = List.first(results)
      IO.puts("  Sample: #{first["technology"] || "(no technology found)"}")
    end
  {:error, error} ->
    IO.puts("✗ Query failed:")
    IO.inspect(error, label: "Error")
    System.halt(1)
end

# Test 2: secure_coding_pattern query
IO.puts("\nTest 2: secure_coding_pattern Cypher query")
IO.puts("Testing with SQLite technology...")

cypher_query2 = """
MATCH (t:Technology)-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
WHERE t.name = $0
OPTIONAL MATCH (bp)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
RETURN bp.name as practice_name,
       bp.category as category,
       bp.description as description,
       bp.code_example as code_example,
       sc.name as security_control
"""

case Graph.query(cypher_query2, ["SQLite"]) do
  {:ok, results} ->
    IO.puts("✓ Query succeeded")
    IO.puts("  Found #{length(results)} best practices")
    if length(results) > 0 do
      first = List.first(results)
      IO.puts("  Sample: #{first["practice_name"] || "(no practice found)"}")
    end
  {:error, error} ->
    IO.puts("✗ Query failed:")
    IO.inspect(error, label: "Error")
    System.halt(1)
end

# Test 3: deployment_guidance query
IO.puts("\nTest 3: deployment_guidance Cypher query")
IO.puts("Testing with Streamlit and SQLite stack...")

cypher_query3 = """
MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase)-[:RECOMMENDED_DEPLOYMENT]->(dp:DeploymentPattern)
WHERE t.name IN $0
RETURN dp.name as pattern_name,
       dp.platform as platform,
       dp.cost as cost,
       dp.complexity as complexity,
       dp.description as description,
       dp.https_support as https_support,
       uc.name as use_case
"""

case Graph.query(cypher_query3, [["Streamlit", "SQLite"]]) do
  {:ok, results} ->
    IO.puts("✓ Query succeeded")
    IO.puts("  Found #{length(results)} deployment patterns")
    if length(results) > 0 do
      first = List.first(results)
      IO.puts("  Sample: #{first["pattern_name"] || "(no pattern found)"}")
    end
  {:error, error} ->
    IO.puts("✗ Query failed:")
    IO.inspect(error, label: "Error")
    System.halt(1)
end

IO.puts("\n=== All tests passed! ===\n")
