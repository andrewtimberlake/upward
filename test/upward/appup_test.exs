# Initial file and fixtures from https://github.com/bitwalker/distillery/blob/master/test/cases/appup_test.exs
defmodule Upward.AppupTest do
  use ExUnit.Case

  alias Upward.Appup
  alias Upward.Appup.Transform

  @fixtures_path Path.join([__DIR__, "..", "fixtures"])

  @v1_path Path.join([@fixtures_path, "appup_beams", "test-0.1.0"])
  @v2_path Path.join([@fixtures_path, "appup_beams", "test-0.2.0"])
  @v3_path Path.join([@fixtures_path, "appup_beams", "test-0.3.0"])

  test "v1 -> v2" do
    # Add ServerB and ServerC gen_servers, update Server to reference ServerB,
    # and ServerB will reference ServerC
    assert {:ok,
            {~c"0.2.0",
             [
               {~c"0.1.0",
                [
                  {:add_module, Test.ServerB},
                  {:add_module, Test.ServerC},
                  {:update, Test.Server, {:advanced, []}, []},
                  {:update, Test.Supervisor, :supervisor}
                ]}
             ],
             [
               {~c"0.1.0",
                [
                  {:delete_module, Test.ServerB},
                  {:delete_module, Test.ServerC},
                  {:update, Test.Server, {:advanced, []}, []},
                  {:update, Test.Supervisor, :supervisor}
                ]}
             ]}} = Appup.make(:test, "0.1.0", "0.2.0", @v1_path, @v2_path)
  end

  test "v2 -> v3" do
    # Server changes to reference ServerC, and ServerC changes to reference ServerB,
    # ServerB changes to no references
    expected =
      {:ok,
       {~c"0.3.0",
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []}
           ]}
        ],
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []}
           ]}
        ]}}

    assert ^expected = Appup.make(:test, "0.2.0", "0.3.0", @v2_path, @v3_path)
  end

  test "v2 -> v3 with transforms" do
    # Server changes to reference ServerC, and ServerC changes to reference ServerB,
    # ServerB changes to no references
    defmodule Upward.AppupTest.TransformTest do
      def up(_app, _v1, _v2, instructions, _opts) do
        instructions ++ [{:update, Phoenix.LiveView.Channel, {:advanced, []}, []}]
      end

      def down(_app, _v1, _v2, instructions, _opts) do
        instructions ++ [{:update, Phoenix.LiveView.Channel, {:advanced, []}, []}]
      end
    end

    expected =
      {:ok,
       {~c"0.3.0",
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []},
             {:update, Phoenix.LiveView.Channel, {:advanced, []}, []}
           ]}
        ],
        [
          {~c"0.2.0",
           [
             {:update, Test.Server, {:advanced, []}, []},
             {:update, Test.ServerB, {:advanced, []}, []},
             {:update, Test.ServerC, {:advanced, []}, []},
             {:update, Phoenix.LiveView.Channel, {:advanced, []}, []}
           ]}
        ]}}

    assert ^expected =
             Appup.make(:test, "0.2.0", "0.3.0", @v2_path, @v3_path, [
               Upward.AppupTest.TransformTest
             ])
  end

  test "transforms" do
    ixs = [
      {:update, Test.Server, {:advanced, []}, []},
      {:load_module, Test.ServerB}
    ]

    transforms = [
      {Appup.SoftPurgeTransform, default: :brutal_purge, overrides: [test: :soft_purge]}
    ]

    transformed =
      Transform.up(ixs, :test, "0.1.0", "0.2.0", transforms)

    expected = [
      {:update, Test.Server, {:advanced, []}, :soft_purge, :soft_purge, []},
      {:load_module, Test.ServerB, :soft_purge, :soft_purge, []}
    ]

    assert ^expected = transformed

    transformed =
      Transform.down(ixs, :test, "0.1.0", "0.2.0", transforms)

    expected = [
      {:update, Test.Server, {:advanced, []}, :soft_purge, :soft_purge, []},
      {:load_module, Test.ServerB, :soft_purge, :soft_purge, []}
    ]

    assert ^expected = transformed
  end
end
