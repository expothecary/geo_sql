{:ok, _} = Application.ensure_all_started(:ecto_sql)

defmodule GeoSQL.Test.PostGIS.Helper do
  def ecto_setup(context) do
    # Since the Repo is not being started by the application under test (this library)
    # it needs to be started. However, to run multiple test suites concurrently, there
    # needs to either be a globally shared Repo, or one Repo per test suite.
    #
    # A globally shared repo is problematic due to not wanting to polute the main library
    # or have a global ExUnit-wide global PID. So instead a repo is started per test suite.
    repo_name = String.to_atom(to_string(context.module) <> "Repo")
    repo_spec = GeoSQL.Test.PostGIS.Repo.child_spec(name: repo_name) |> Map.put(:id, repo_name)
    pid = ExUnit.Callbacks.start_link_supervised!(repo_spec)

    # Set the dynamic repo name within the parent test suite process to that any setup functions
    # in the test suite itself have access to the repo
    GeoSQL.Test.PostGIS.Repo.put_dynamic_repo(repo_name)

    # Add the repo pid and name into the context so that tests can access it
    [repo: pid, repo_name: repo_name]
  end

  def ecto_async_prep(context) do
    Ecto.Adapters.SQL.Sandbox.mode(context.repo, :manual)
    :ok
  end

  defmacro __using__(options \\ []) do
    setup_funs = Keyword.get(options, :setup_funs, [])

    quote do
      alias GeoSQL.Test.PostGIS.Repo, as: PostGISRepo

      setup_all [{GeoSQL.Test.PostGIS.Helper, :ecto_setup}] ++
                  unquote(setup_funs) ++ [{GeoSQL.Test.PostGIS.Helper, :ecto_async_prep}]

      setup context do
        # In the per-test context, register the name of the dynamic repo.
        GeoSQL.Test.PostGIS.Repo.put_dynamic_repo(context.repo_name)

        # Get a repo pid for ourselves here, via the repository that was started in setup_all
        pid = Ecto.Adapters.SQL.Sandbox.start_owner!(context.repo, shared: not context[:async])

        # Register an on_exit handler that stops that pid
        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        :ok
      end
    end
  end
end

ExUnit.start()
