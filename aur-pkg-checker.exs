defmodule AurChecker do

  @doc """
  Run system command 'pacman -Qm' and return its raw output.
  """
  def run_pacman_command() do
    case System.cmd("pacman", ["-Qm"]) do
      {string, 0} -> {:ok, string}
      [] -> :error
    end
  end

  @doc """
  Parse raw output from 'pacman -Qm' to 'map' of installed packages.

  Returns a list of maps in format [%{name: name, version: version}].
  """ 
  def parse_pacman_command(string) do
    items = String.split(string, "\n")
    Enum.map(items, fn item ->
      case String.split(item, " ") do
        [name, version] -> %{name: name, version: version}
        [""] -> nil
      end
    end)
  end

  @doc """
  Read the installed packages.
  """
  def get_installed_packages() do
    {:ok, rawstring} = run_pacman_command()
    parse_pacman_command(rawstring)
  end

  @doc """
  Fetch the latest package versions from AUR.

  Returns a map in format %{name: name, version: version}.
  """
  def fetch_latest_version_info(packagename) do
    fetch_url = to_char_list("http://aur.archlinux.org/packages/" <> packagename)
    IO.puts fetch_url
    :inets.start
    :ssl.start
    {:ok, {{_version, 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {fetch_url,
        []}, [{:ssl,[{:verify,0}]}], [])

    # Parse 
    rawlines = String.split(to_string(body), "\n")
    versionline = Enum.filter(rawlines, fn line ->
      Regex.match?(~r/Package Details:\s/, line) end)
    [name, version] = String.split(to_string(versionline), ["\t<h2>Package Details: "," ","</h2>"], trim: true)
    %{name: name, version: version}
  end
end
