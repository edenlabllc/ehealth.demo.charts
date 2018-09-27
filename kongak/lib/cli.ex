defmodule Kongak.CLI do
  @moduledoc false

  alias Kongak

  def main(["apply" | args]), do: Kongak.apply(args)
  def main(["dump" | args]), do: Kongak.dump(args)
  def main(["-V" | _]), do: IO.puts(Kongak.MixProject.project()[:version])

  def main(_) do
    IO.puts("""
    Usage: kongak [options] [command]

    Options:

      -V, --version  output the version number
      -h, --help     output usage information

    Commands:

      apply          Apply config to a kong server
      dump           Dump the configuration from a kong server
      help [cmd]     display help for [cmd]

    """)
  end
end
