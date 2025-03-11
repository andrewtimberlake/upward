defmodule Upward.Transformers.PhoenixLiveViewTransformer do
  @moduledoc """
  An appup transformer for Phoenix LiveView.

  If this transformer is included, it will append instructions to have all
  Phoenix LiveView channels updated.

  If you want your LiveView to be updated during an upgrade/downgrade,
  you should implement `code_change/3` in your LiveView.

  ```elixir
  def code_change(_old_vsn, socket, _extra) do
    {:ok, socket}
  end
  ```

  `old_vsn` will be the previous version of the Channel (not the LiveView) and `{down: old_vsn}` during a downgrade.
  Because the version is the version of the Channel, you should implement your own version tracking within the socket private or assigns.
  """

  def up(_app, _v1, _v2, instructions, _opts) do
    instructions ++ [{:update, Phoenix.LiveView.Channel, {:advanced, []}}]
  end

  def down(_app, _v1, _v2, instructions, _opts) do
    instructions ++ [{:update, Phoenix.LiveView.Channel, {:advanced, []}}]
  end
end
