defmodule LazadaScrape do
  require Elixlsx
  alias Elixlsx.{Workbook, Sheet}

  def headers do
    [
      {"User-Agent",
       "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"},
      {"Cookie",
       "client_type=desktop; hng=TH|th|THB|764; hng.sig=SsL2tV4PEb-QdHuP4Um9myn_3RH9bJSEN4qP2UfjzMM; lzd_cid=abc6a84b-74ca-4208-9dda-644840c11eee; t_uid=abc6a84b-74ca-4208-9dda-644840c11eee; lwrid=AQGIo53EfmMJLweJkk932RpuI%2Bis; t_fv=1686372205717; cna=oeEEHSRwvR8CAX0YDyEMYpAU; lzd_sid=15bbe20a192bab912daac7b7969c4377; _tb_token_=3111183dd389; _gcl_au=1.1.2119362657.1686459920; lazada_share_info=532977529_2_7900_100155738439_532977529_null; _m_h5_tk=55acaabff6a8c5177f97cad69cdbb73c_1686846145429; _m_h5_tk_enc=6eddf97acce1c043dfbc2e1e49f75d69; xlly_s=1; _ga=GA1.3.1181011635.1686835713; _gid=GA1.3.1356771780.1686835713; AMCVS_126E248D54200F960A4C98C6%40AdobeOrg=1; AMCV_126E248D54200F960A4C98C6%40AdobeOrg=-1124106680%7CMCIDTS%7C19524%7CMCMID%7C60773271296604329272961556073582192858%7CMCAAMLH-1687440514%7C3%7CMCAAMB-1687440514%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1686842914s%7CNONE%7CvVersion%7C5.2.0; t_sid=GzOqXDWVjWXhkHShO4nayoYw9XOS0fzM; utm_channel=NA; x5sec=7b22617365727665722d6c617a6164613b32223a223464613330353236363162393731623837333636343230643364396261393534434f5454724b5147454d62356a4d367176626233397745777765576e35506a2f2f2f2f2f41554143222c22733b32223a226631323630316261386464643637363236376365303366626337313963666161227d; _uetsid=c68a91e00b8e11eeb56ef5311b0cff1b; _uetvid=c68b3e300b8e11ee831cc5e9c593273f; _gat_UA-30236174-1=1; tfstk=cN-1BFtRFTfelqo0j1MeVDHV2CjRZAPC356eCb93iJLbGsv1iCEPNr8LmJsVH91..; l=fBMB-TuqNK94IpUFXOfwFurza77tIIRAguPzaNbMi9fPsu1H5KRAW11GcgYMCnMNFswHR3RB4oKJBeYBYSDX5FHUVb9MPUMmneaOL41..; isg=BG5usRVEhtJeifK-N8p0829Hv80wbzJp9Bipnpg33HEsew7VAP2Vefz9M_-XoyqB"}
    ]
  end

  def fetch_shop do
    1..1
    |> Enum.map(&fetch_shop(&1))
    |> List.flatten()
    # |> Enum.take(2)
    |> Enum.map(fn url ->
      try do
        fetch_product(url)
      rescue
        _ -> nil
      end
    end)
    |> Enum.filter(&(!is_nil(&1)))
    |> List.flatten()
    |> write_to_csv
  end

  def fetch_shop(page) do
    "https://www.lazada.co.th/deehouse-store/?ajax=true&from=wangpu&isFirstRequest=true&langFlag=th&page=#{page}&pageTypeId=2&q=All-Products"
    |> HTTPoison.get!(headers)
    |> (& &1.body).()
    |> Jason.decode!()
    |> get_in(["mods", "listItems"])
    |> Enum.map(&("http:" <> &1["itemUrl"]))
  end

  def fetch_product(url) do
    # "https://www.lazada.co.th/products/clamp-10-5cm-i4078696396.html"
    url
    |> String.replace("http://", "https://")
    |> HTTPoison.get!(headers)
    |> (& &1.body).()
    |> (&Regex.replace(~r/\n/, &1, "", global: true)).()
    |> (&Regex.replace(~r/\r/, &1, "", global: true)).()
    |> (&Regex.run(~r/__moduleData__ = (.+?)var __googleBot__/, &1, capture: :all_but_first)).()
    |> Enum.at(0)
    |> String.trim()
    |> String.slice(0..-2)
    |> Jason.decode!()
    |> get_in(["data", "root", "fields"])
    |> (&[
          %{
            "url" => url,
            "category_id" => "100008",
            "name" => get_in(&1, ["product", "title"]),
            "description" => get_in(&1, ["product", "desc"]),
            "sku" => get_in(&1, ["primaryKey", "skuId"]),
            "price" => "",
            "quantity" => 10,
            "image_cover" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(0) |> get_in(["poster"]) |> image_url,
            "image0" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(0) |> get_in(["poster"]) |> image_url,
            "image1" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(1) |> get_in(["poster"]) |> image_url,
            "image2" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(2) |> get_in(["poster"]) |> image_url,
            "image3" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(3) |> get_in(["poster"]) |> image_url,
            "image4" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(4) |> get_in(["poster"]) |> image_url,
            "image5" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(5) |> get_in(["poster"]) |> image_url,
            "image6" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(6) |> get_in(["poster"]) |> image_url,
            "image7" =>
              get_in(&1, ["skuGalleries", "0"]) |> Enum.at(7) |> get_in(["poster"]) |> image_url,
            "weight" => 0.5,
            "brand" => "มาดามหมอ"
          }
        ]).()
  end

  def image_url(url) do
    "https:#{url}"
  end

  def write_to_csv(data) do
    headers = Enum.at(data, 0) |> Map.keys()

    sheet = %Sheet{
      name: "Data",
      rows: [
        headers
        | Enum.map(data, fn r ->
            Enum.map(headers, fn c ->
              Map.get(r, c)
            end)
          end)
      ],
      row_heights: %{4 => 60}
    }

    workbook = %Workbook{sheets: [sheet]}

    Workbook.append_sheet(%Workbook{}, sheet)
    |> Elixlsx.write_to("data_lazada.xlsx")
  end
end
