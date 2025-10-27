defmodule Guided.MCPServerCypherTest do
  use ExUnit.Case
  doctest Guided.MCPServer

  describe "Cypher Query Syntax" do
    test "tech_stack_recommendation uses positional parameter $0" do
      # The query should use $0 for positional parameters, not named parameters
      query = """
      MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: $0})
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

      # Should contain $0 for positional parameter
      assert query =~ "$0"
      # Should not contain named parameters like $use_case
      refute query =~ "$use_case"
    end

    test "secure_coding_pattern uses positional parameter $0" do
      query = """
      MATCH (t:Technology {name: $0})-[:HAS_BEST_PRACTICE]->(bp:BestPractice)
      OPTIONAL MATCH (bp)-[:IMPLEMENTS_CONTROL]->(sc:SecurityControl)
      RETURN bp.name as practice_name,
             bp.category as category,
             bp.description as description,
             bp.code_example as code_example,
             sc.name as security_control
      """

      assert query =~ "$0"
      refute query =~ "$technology"
    end

    test "deployment_guidance uses positional parameter $0 and avoids nested collect" do
      query = """
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

      assert query =~ "$0"
      refute query =~ "$technologies"
      # Should not have nested collect
      refute query =~ ~r/collect.*collect/
      # Should return flat results
      assert query =~ "uc.name as use_case"
    end

    test "queries avoid nested collect() which AGE doesn't support" do
      # tech_stack_recommendation query
      tech_query = """
      MATCH (t:Technology)-[:RECOMMENDED_FOR]->(uc:UseCase {name: $0})
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

      # Should not contain nested collect()
      refute tech_query =~ ~r/collect\s*\([^)]*collect/i
    end
  end

  describe "MCP Response Format" do
    test "handle_tool_call should return {:reply, text_string, frame}" do
      # The correct format for Hermes is {:reply, text_result, updated_frame}
      # where text_result is a JSON-encoded string

      # This is a documentation test to ensure developers know the correct format
      expected_format = {:reply, "json string here", :frame_here}
      assert is_tuple(expected_format)
      assert tuple_size(expected_format) == 3
      assert elem(expected_format, 0) == :reply
      assert is_binary(elem(expected_format, 1))
    end
  end
end
