# Upward

An opinionated library to assist with hot-code upgrades with Elixir releases

## Installation

Add `:upward` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:upward, "~> 0.0"}
  ]
end
```

## Philosophy

Elixir, built on top of Erlang OTP, has an incredibly powerful feature of being able to hot-swap code on a running system.
Like all the powerful features that come with OTP, it has the potential to be very complex and difficult to understand.

Upward is built to provide a simple approach to hot-code upgrades, and purposefully limits hot-code upgrades to patch releases.

The idea being that you are able to release early and release often, but when you make significant changes, like adding or upgrading dependencies, altering your supervision tree, or similar, you create a new minor or major release.

When you do a patch release, Upward will automatically generate an appup file with the changes needed to upgrade from the previous release to the new one.
When you do a minor or major release, Upward will not generate an appup file, but will instead create a new RELEASES file which will service as the bases for future patch releases.
You should then restart your system using an appropriate strategy, like a rolling restart or a blue/green deployment.

You will be able to do hot-rollbacks through patch releases, back to the last minor or major release.

### Phoenix LiveView

Without hot-code upgrades, Phoenix LiveView applications will have to reconnect the socket and regenerate state for every update. Clients will receive reconnection messages and similar UI irritations. This is completely unnecessary if you’re making simple changes to your codebase.

By using upward, you can minimise discruptions, especially for long-running sessions.

## Usage

Add `&Upward.auto_appup/1` to your release steps in `mix.exs`.

```elixir
  def releases do
    [
      my_app: [
        include_executables_for: [:unix],
        steps: [:assemble, &Upward.auto_appup/1, :tar]
      ]
    ]
  end
```

### Usage with Phoenix LiveView

Phoenix LiveView channels can be updated during a patch release by implementing the `code_change/3` callback in your LiveView.
But, your LiveView runs within the context of a Phoenix Channel, so code_change is only called if the Channel is set to update. In order to do that, we need to add an update instruction for the channel within the app up.

If you want `code_change/3` to be called on your liveviews during an upgrade, then add `Upward.Transformers.PhoenixLiveViewTransformer` to the auto_appup step in your release config.

See instructions at `Upward.Transformers.PhoenixLiveViewTransformer` for more information.


### Upgrading your app
For each patch release, you will need run the upgrade from within your app using `Upward.upgrade/0`.

Here are the release steps:
1. `mix release`
2. Copy the tarball to the target machine
3. Extract the tarball to the release directory
4. Run `Upward.upgrade/0`
   - `$ bin/my_app rpc 'Upward.upgrade()'`

To rollback to a previous version, run `Upward.downgrade/0`.

You can also run `Upward.install/1` with a specific version to install a specific version. It is up to you to ensure that the version you select is the next version up or down from the current running version.

## Author
[Andrew Timberlake](https://andrewtimberlake.com)
If you need help with your Elixir or Phoenix project, [I'm available for hire](https://andrewtimberlake.com/hire).

## Versioning
This library follows [Semantic Versioning](https://semver.org/), and expects you to follow the same ;-).
