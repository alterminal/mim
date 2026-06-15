defmodule Mim.Versions do
  @moduledoc """
  Builds the supported client-server API versions response for
  `GET /_matrix/client/versions`.
  """

  @supported_versions [
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
  ]

  @unstable_features %{
    "org.matrix.msc2965.authentication" => true,
    "org.matrix.msc3824.delegated_oidc_compatibility" => true
  }

  @doc """
  Returns the versions document for `GET /_matrix/client/versions`.
  """
  @spec document() :: map()
  def document do
    %{
      "versions" => @supported_versions,
      "unstable_features" => @unstable_features
    }
  end
end
