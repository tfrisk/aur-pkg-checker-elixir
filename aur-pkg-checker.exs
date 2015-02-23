defmodule AurChecker do

  # Run system command 'pacman -Qm' and return its raw output.
  defp run_pacman_command() do
    case System.cmd("pacman", ["-Qm"]) do
      {string, 0} -> {:ok, string}
      [] -> :error
    end
  end

  # Run system command 'vercmp v1 v2' and return status message
  # based on the result.
  defp run_vercmp_command(v1, v2) do
    case System.cmd("vercmp", [v1, v2]) do
      {"-1\n", 0} -> "new version available: #{v2}"
      {"0\n", 0} -> "OK"
      {"1\n", 0} -> "newer version installed: #{v2}"
      [] -> :error
    end
  end

  # Parse raw output from 'pacman -Qm' to 'map' of installed packages.
  # Returns a list of maps in format [%{name: name, version: version}].
  defp parse_pacman_command(string) do
    items = String.split(string, "\n", trim: true)
    Enum.map(items, fn item ->
      case String.split(item, " ") do
        [name, version] -> %{name: name, version: version}
      end
    end)
  end

  # Fetch specified 'url' and return the response body.
  defp fetch_url(url) do
    :inets.start
    :ssl.start
    {:ok, {{_version, 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {url,
        []}, [{:ssl,[{:verify,0}]}], [])
    body
  end

  # Fetch the latest package versions from AUR.
  # Returns a map in format %{name: name, version: version}.
  defp fetch_latest_version_info(packagename) do
    url = to_char_list("http://aur.archlinux.org/packages/" <> packagename)
    body = fetch_url(url)

    # Parse version info from response
    rawlines = String.split(to_string(body), "\n")
    versionline = Enum.filter(rawlines, fn line ->
      Regex.match?(~r/Package Details:\s/, line) end)
    [name, version] = String.split(to_string(versionline), ["\t<h2>Package Details: "," ","</h2>"], trim: true)
    %{name: name, version: version}
  end

  # Compares the current and latest versions for a given package map.
  defp compare_versions(current, latest) do
    run_vercmp_command(current, latest)
  end

  @doc """
  Read the installed packages.

  Returns a list of maps in format [%{name: name, version: version}].
  """
  def get_installed_packages() do
    {:ok, rawstring} = run_pacman_command()
    parse_pacman_command(rawstring)
  end

  @doc """
  Enumerate 'packagelist' and get the latest package versions
  for these packages from AUR. Compares the versions and updates
  the status accordingly.

  Returns a list of maps in format
  [%{name: x, currentversion: y, latestversion: z, status: s}].
  """
  def get_updated_packages(packagelist) do
    Enum.map(packagelist, fn package ->
      %{name: _, version: latestversion} = fetch_latest_version_info(package.name)
      %{name: package.name,
        currentversion: package.version,
        latestversion: latestversion,
        status: compare_versions(package.version, latestversion)}
    end)
  end
end


installed = AurChecker.get_installed_packages
updatelist = AurChecker.get_updated_packages(installed)

# Current time, pretty ugly code. Should use Timex library instead.
{{year,month,day}, {hour,minute,second}} = :calendar.local_time
IO.puts "Current time is #{year}-#{month}-#{day} #{hour}:#{minute}:#{second}"
IO.puts "Checking package versions"
Enum.map updatelist, fn item ->
  IO.puts "#{item.name}: #{item.currentversion} => #{item.status}"
end
