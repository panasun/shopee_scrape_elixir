defmodule LazadaScrape do
  require Elixlsx
  alias Elixlsx.{Workbook, Sheet}

  def fetch_shop do
    1..1
    |> Enum.map(&fetch_shop(&1))
    |> List.flatten()
  end

  def fetch_shop(page) do
    "https://www.lazada.co.th/deehouse-store/?ajax=true&from=wangpu&isFirstRequest=true&langFlag=th&page=#{page}&pageTypeId=2&q=All-Products"
    |> HTTPoison.get!()
    |> (& &1.body).()
    |> Jason.decode!()
    |> get_in(["mods", "listItems"])
    |> Enum.map(&("http:" <> &1["itemUrl"]))
  end

  def fetch_product() do
    "https://www.lazada.co.th/products/clamp-10-5cm-i4078696396.html"
    |> HTTPoison.get!()
    |> (& &1.body).()
    |> (&Regex.replace(~r/\n/, &1, "", global: true)).()
    |> (&Regex.replace(~r/\r/, &1, "", global: true)).()
    |> (&Regex.run(~r/__moduleData__ = (.+?)var __googleBot__/, &1, capture: :all_but_first)).()
    |> Enum.at(0)
    |> String.trim()
    |> String.slice(0..-2)
    |> Jason.decode!()
  end
end
