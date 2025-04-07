defmodule Upward.Config do
  @doc """
  Returns a tuple with the new config, the changed config, and the removed config.
  new - config with a key that is not in the previous config
  changed - config with a key that is in the previous config and has a different value
  removed - list of keys that are in the previous config but not in the new config
  """
  def diff(app_name, previous_env) when is_atom(app_name) do
    current_env = Application.get_all_env(app_name)
    diff(current_env, previous_env)
  end

  def diff(current_env, previous_env) do
    calculate_diff(current_env, previous_env, {[], []})
  end

  defp calculate_diff([], previous_env, {changed, new}) do
    removed = Enum.reduce(previous_env, [], fn {key, _value}, acc -> [key | acc] end)
    {changed, new, removed}
  end

  defp calculate_diff(current_env, [], {changed, new}) do
    {changed, current_env ++ new, []}
  end

  defp calculate_diff([{key, value} | current_env], previous_env, {changed, new}) do
    case List.keyfind(previous_env, key, 0) do
      {key, ^value} ->
        calculate_diff(current_env, List.keydelete(previous_env, key, 0), {changed, new})

      {key, _other_value} ->
        calculate_diff(
          current_env,
          List.keydelete(previous_env, key, 0),
          {[{key, value} | changed], new}
        )

      nil ->
        calculate_diff(current_env, previous_env, {changed, [{key, value} | new]})
    end
  end
end
