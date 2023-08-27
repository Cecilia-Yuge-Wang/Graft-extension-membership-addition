### This repository is a extension of Graft with the member addition function.

A add_member function is added to the original Graft library.

### A example:
Get dependencies:
```cmd
path\graft> mix deps.get
Resolving Hex dependencies...
```
Start the application
```cmd
path\graft> iex -S mix
```
```shell
iex(1)> Graft.start
[:ok, :ok, :ok, :ok, :ok]
```
Add new members
```shell
iex(2)> Graft.add_member(:server1,[:server9, :server8])
"Member change processing..."
```



The original library：
# Graft
Graft offers an Elixir implementation of the raft consensus algorithm, allowing the creation of a distributed cluster of servers, where each server manages a replicated state machine. The `Graft.Machine` behaviour allows users to define their own replicated state machines, that may handle user defined client requests.

In this project's documentation you will find terminology that has been defined in the [raft paper](https://raft.github.io/raft.pdf). The docs do not go into specifics of the raft algorithm, so if you wish to learn more about how raft achieves consensus, the [official raft webpage](https://raft.github.io/) is a great place to start.

## Installation
To install the package, add it to your dependency list in `mix.exs`.

```elixir
def deps do
    [{:graft, "~> 0.1.1"}]
end
```
If you are new to Elixir/mix, check out the [official Elixir webpage](https://elixir-lang.org/) for instructions on how to install Elixir. It is also a great place to start for newcomers to the language. You may also want to check out the [Introduction to mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) and [dependencies](https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html) guides for more information on how importing external projects works in Elixir.

## Documentation
Find the full documentation as well as examples [here](https://hexdocs.pm/graft/Graft.html).
