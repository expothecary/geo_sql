{:ok, _} = Application.ensure_all_started(:ecto_sql)

defmodule GeoSQL.Test.Helper do
  def repos() do
    Application.get_env(:geo_sql, :ecto_repos)
  end

  def is_a(%x{}, which), do: Enum.member?(which, x)
  def is_a(_, _), do: false

  def fuzzy_match_geometry([left], [right]) when is_list(left) and is_list(right) do
    fuzzy_match_geometry(left, right)
  end

  def fuzzy_match_geometry(left, right) when is_list(left) and is_list(right) do
    Enum.zip(left, right)
    |> Enum.reduce_while(
      true,
      fn {l, r}, _acc ->
        cond do
          is_list(l) and is_list(r) ->
            result =
              Enum.zip(l, r)
              |> Enum.reduce(true, fn {l, r}, acc ->
                acc and Float.round(l, 4) == Float.round(r, 4)
              end)

            if result, do: {:cont, true}, else: {:halt, false}

          is_number(l) and is_number(r) and Float.round(l, 4) == Float.round(r, 4) ->
            {:cont, true}

          true ->
            {:halt, false}
        end
      end
    )
  end

  def fuzzy_match_geometry(_l, _r), do: false

  defmacro __using__(options \\ []) do
    setup_funs = Keyword.get(options, :setup_funs, [])

    quote do
      alias GeoSQL.Test.PostGIS.Repo, as: PostGISRepo
      alias GeoSQL.Test.SQLite3.Repo, as: SQLite3Repo
      alias GeoSQL.Test.Fixtures
      alias GeoSQL.Test.Helper

      setup_all [{GeoSQL.Test.Helper, :ecto_setup_all}] ++ unquote(setup_funs)

      setup context do
        for repo <- GeoSQL.Test.Helper.repos() do
          GeoSQL.Test.Helper.ecto_setup(repo, context)
        end

        :ok
      end
    end
  end

  def ecto_setup_all(context) do
    Enum.reduce(repos(), [repo_info: %{}], fn repo, acc ->
      repo_name = String.to_atom(to_string(context.module) <> repo_name_suffix(repo))
      ecto_setup_repo(repo, repo_name, acc)
    end)
  end

  def repo_info(repo, %{repo_info: repo_info}) do
    Map.get(repo_info, repo)
  end

  # Since the Repo is not being started by the application under test (this library)
  # it needs to be started. However, to run multiple test suites concurrently, there
  # needs to either be a globally shared Repo, or one Repo per test suite.
  #
  # A globally shared repo is problematic due to not wanting to polute the main library
  # or have a global ExUnit-wide global PID. So instead a repo is started per test suite.
  def repo_name_suffix(GeoSQL.Test.PostGIS.Repo), do: "PostGISRepo"
  def repo_name_suffix(GeoSQL.Test.SQLite3.Repo), do: "SQLite3Repo"

  def ecto_setup_repo(repo, repo_name, acc) do
    repo_spec =
      repo.child_spec(name: repo_name)
      |> Map.put(:id, repo_name)

    # horrible hack here, but we need to start repo supervised for setup_all functions
    # that need access to a global db object they can modify for all tests aftewards.
    try do
      ExUnit.Callbacks.start_link_supervised!(repo.child_spec([]))

      GeoSQL.init(repo, json: Jason, decode_binary: :reference)
    rescue
      _ -> :ok
    end

    pid = ExUnit.Callbacks.start_link_supervised!(repo_spec)

    # Add the repo pid and name into the context so that tests can access it
    add_repo_to_context(repo, pid, repo_name, acc)
  end

  defp add_repo_to_context(repo, pid, name, context) do
    info =
      %{pid: pid, name: name}

    repo_info =
      Keyword.get(context, :repo_info)
      |> Map.put(repo, info)

    Keyword.put(context, :repo_info, repo_info)
  end

  def ecto_setup(repo, context) do
    # In the per-test context, register the name of the dynamic repo.
    info = repo_info(repo, context)

    repo.put_dynamic_repo(info.name)
    #     :ok = Ecto.Adapters.SQL.Sandbox.checkout(info.pid)
    # Get a repo pid for ourselves here, via the repository that was started in setup_all
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(info.pid, shared: not context[:async])

    #     GeoSQL.init(repo, json: Jason, decode_binary: :reference)
    # Register an on_exit handler that stops that pid
    ExUnit.Callbacks.on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

excludable_tags = [:pgsql]

exclude_tags =
  GeoSQL.Test.Helper.repos()
  |> Enum.reduce(
    excludable_tags,
    fn
      repo, exclude_tags ->
        case repo.__adapter__() do
          Ecto.Adapters.Postgres -> Enum.reject(exclude_tags, fn tag -> tag == :pgsql end)
          _ -> exclude_tags
        end
    end
  )

ExUnit.start(exclude: exclude_tags)
