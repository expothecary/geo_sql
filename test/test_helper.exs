{:ok, _} = Application.ensure_all_started(:ecto_sql)

defmodule GeoSQL.Test.Helper do
  def repos() do
    Application.get_env(:geo_sql, :ecto_repos)
  end

  def is_a(%x{}, which), do: Enum.member?(which, x)
  def is_a(_, _), do: false

  defmacro __using__(options \\ []) do
    setup_funs = Keyword.get(options, :setup_funs, [])

    quote do
      alias GeoSQL.Test.PostGIS.Repo, as: PostGISRepo
      alias GeoSQL.Test.SQLite3.Repo, as: SQLite3Repo
      alias GeoSQL.Test.Fixtures

      setup_all [{GeoSQL.Test.Helper, :ecto_setup_all}] ++
                  unquote(setup_funs) ++ [{GeoSQL.Test.Helper, :ecto_async_prep}]

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

    pid = ExUnit.Callbacks.start_link_supervised!(repo_spec)

    # Set the dynamic repo name within the parent test suite process so that any setup functions
    # in the test suite itself have access to the repo
    GeoSQL.init(repo, json: Jason, decode_binary: :reference)

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

  def ecto_async_prep(context) do
    repo_pid = Map.get(context, :repo)

    if repo_pid != nil do
      Ecto.Adapters.SQL.Sandbox.mode(context.repo, :manual)
    end

    :ok
  end

  def ecto_setup(repo, context) do
    # In the per-test context, register the name of the dynamic repo.
    info = repo_info(repo, context)

    repo.put_dynamic_repo(info.name)

    # Get a repo pid for ourselves here, via the repository that was started in setup_all
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(info.pid, shared: not context[:async])

    #     GeoSQL.init(repo, json: Jason, decode_binary: :reference)
    # Register an on_exit handler that stops that pid
    ExUnit.Callbacks.on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end
end

ExUnit.start()
