defmodule Mim.VersionsTest do
  use ExUnit.Case, async: true

  alias Mim.Versions

  test "document/0 returns supported versions and unstable features" do
    assert %{
             "versions" => [
               "r0.0.1",
               "r0.1.0",
               "r0.2.0",
               "r0.3.0",
               "r0.4.0",
               "r0.5.0",
               "r0.6.0",
               "r0.6.1",
               "v1.1",
               "v1.2",
               "v1.3",
               "v1.4",
               "v1.5",
               "v1.6",
               "v1.7",
               "v1.8",
               "v1.9",
               "v1.10",
               "v1.11"
             ],
             "unstable_features" => %{
               "org.matrix.msc2965.authentication" => true,
               "org.matrix.msc3824.delegated_oidc_compatibility" => true
             }
           } = Versions.document()
  end
end
