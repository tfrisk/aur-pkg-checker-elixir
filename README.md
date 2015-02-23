# AUR package checker

A command line tool for checking local packages installed from AUR (Arch User Repository).

Elixir version of https://github.com/tfrisk/aur-pkg-checker (which is written in Ruby).

## Requirements

* Arch Linux
* Erlang
* Elixir (http://elixir-lang.org/)

## Usage

The program checks your local installed packages (with <code>pacman -Qm</code>) and then performs a check againts the latest versions in AUR (https://aur.archlinux.org/). The version comparison is done with <code>vercmp</code> which guarantees compatibility with <code>pacman</code>.

Example:
<pre>
$ elixir aur-pkg-checker.exs
Current time is 2015-02-11 11:49:07
Checking package versions
libudev.so.0: 0.1.1-2 => OK
lighttable: 0.7.2-1 => OK
sublime-text: 2.0.2-1 => new version available: 2.0.2-4
</pre>

In this example the user has 3 installed packages. Two of these packages are up-to-date, and one has a newer version available.

The program can be run with regular user privileges.

## TODO

* Command line options
* Download updated packages
* Log actions
* Ignored package list (don't want to update certain packages)
* Install new packages


Copyright (C) 2015 Teemu Frisk
Distributed under MIT License
