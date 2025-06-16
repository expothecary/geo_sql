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
    GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)

    # Add the repo pid and name into the context so that tests can access it
    [repo: pid, repo_name: repo_name]
  end

  def ecto_async_prep(context) do
    Ecto.Adapters.SQL.Sandbox.mode(context.repo, :manual)
    :ok
  end

  def multipoint_wkb() do
    "0106000020E6100000010000000103000000010000000F00000091A1EF7505D521C0F4AD6182E481424072B3CE92FED421C01D483CDAE281424085184FAEF7D421C0CB159111E1814240E1EBD7FBF8D421C0D421F7C8DF814240AD111315FFD421C0FE1F21C0DE81424082A0669908D521C050071118DE814240813C5E700FD521C0954EEF97DE814240DC889FA815D521C0B3382182E08142400148A81817D521C0E620D22BE2814240F1E95BDE19D521C08BD53852E3814240F81699E217D521C05B35D7DCE4814240B287C8D715D521C0336338FEE481424085882FB90FD521C0FEF65484E5814240A53E1E460AD521C09A0EA286E581424091A1EF7505D521C0F4AD6182E4814240"
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

        GeoSQL.init(GeoSQL.Test.PostGIS.Repo, json: Jason, decode_binary: :reference)
        # Register an on_exit handler that stops that pid
        on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
        :ok
      end
    end
  end
end

ExUnit.start()
