defmodule ShopeeScrape do
  require Elixlsx
  alias Elixlsx.{Workbook, Sheet}

  def fetch_shop do
    0..1
    |> Enum.map(&fetch_shop(&1))
    |> List.flatten()
    # |> Enum.take(12)
    |> Enum.map(fn r ->
      try do
        fetch_product(r)
      rescue
        _ -> nil
      end
    end)
    |> Enum.filter(&(!is_nil(&1)))
    |> List.flatten()
    |> write_to_csv
  end

  def fetch_shop(page) do
    "https://shopee.co.th/api/v4/shop/rcmd_items?bundle=shop_page_category_tab_main&limit=100&offset=#{page * 100}&shop_id=513196974&sort_type=1"
    |> HTTPoison.get!()
    |> (& &1.body).()
    |> Jason.decode!()
    |> get_in(["data", "items"])
    |> Enum.map(& &1["itemid"])
  end

  def fetch_product(item_id) do
    "https://shopee.co.th/api/v4/item/get?shopid=513196974&itemid=#{item_id}"
    |> HTTPoison.get!()
    |> (& &1.body).()
    |> Jason.decode!()
    |> get_in(["data"])
    |> (&([
            %{
              "category_id" => "100825",
              "name" => Map.get(&1, "name"),
              "description" => Map.get(&1, "description"),
              "sku" => Map.get(&1, "itemid"),
              "price" => Map.get(&1, "price") / 100_000,
              "quantity" => 10,
              "hscode" => "0902",
              "tax" => "GEN_Zero",
              "image" => Map.get(&1, "image") |> image_url,
              "image_cover" => Map.get(&1, "image") |> image_url,
              "image0" => Map.get(&1, "images") |> Enum.at(0) |> image_url,
              "image1" => Map.get(&1, "images") |> Enum.at(1) |> image_url,
              "image2" => Map.get(&1, "images") |> Enum.at(2) |> image_url,
              "image3" => Map.get(&1, "images") |> Enum.at(3) |> image_url,
              "image4" => Map.get(&1, "images") |> Enum.at(4) |> image_url,
              "image5" => Map.get(&1, "images") |> Enum.at(5) |> image_url,
              "image6" => Map.get(&1, "images") |> Enum.at(6) |> image_url,
              "image7" => Map.get(&1, "images") |> Enum.at(7) |> image_url,
              "weight" => 0.5,
              "brand" => "มาดามหมอ",
              "country_of_origin" => "Thailand",
              "manufacturer_details" => "TCHA #{Map.get(&1, "itemid")}"
            },
            Map.get(&1, "models")
            |> Enum.with_index()
            |> Enum.map(fn {value, index} ->
              %{
                "category_id" => "100825",
                "name" => Map.get(&1, "name"),
                "description" => Map.get(&1, "description"),
                "sku" => Map.get(value, "itemid"),
                "parent_sku" => Map.get(&1, "itemid"),
                "variation_type" => "ประเภท",
                "variation_name" => Map.get(value, "name"),
                "price" => Map.get(value, "price") / 100_000,
                "quantity" => 10,
                "hscode" => "0902",
                "tax" => "GEN_Zero",
                "image" =>
                  Map.get(&1, "tier_variations")
                  |> Enum.at(0)
                  |> Map.get("images")
                  |> Enum.at(index)
                  |> image_url,
                "image_cover" =>
                  Map.get(&1, "tier_variations")
                  |> Enum.at(0)
                  |> Map.get("images")
                  |> Enum.at(index)
                  |> image_url,
                "weight" => 0.5,
                "brand" => "มาดามหมอ",
                "country_of_origin" => "Thailand",
                "manufacturer_details" => "TCHA #{Map.get(value, "itemid")}"
              }
            end)
          ]
          |> List.flatten())).()
  end

  def image_url(name) do
    if name == nil do
      ""
    else
      "https://down-th.img.susercontent.com/file/#{name}"
    end
  end

  def write_to_csv(data) do
    new_data =
      Enum.map(data, fn r ->
        Map.new(r, fn {key, value} ->
          case key do
            "category_id" -> {"หมวดหมู่สินค้า", value}
            "name" -> {"ชื่อสินค้า", value}
            "description" -> {"รายละเอียดสินค้า", value}
            "parent_sku" -> {"เลขอ้างอิงตัวเลือกสินค้า", value}
            "variation_type" -> {"ชื่อตัวเลือก 1", value}
            "variation_name" -> {"ตัวเลือก 1", value}
            "image" -> {"ภาพตัวเลือก", value}
            "image_cover" -> {"ภาพปก", value}
            "price" -> {"ราคา", value}
            "quantity" -> {"คลังสินค้า", value}
            "sku" -> {"เลข SKU", value}
            "hscode" -> {"HS Code", value}
            "tax" -> {"Tax Code", value}
            "image0" -> {"รูปภาพ 1", value}
            "image1" -> {"รูปภาพ 2", value}
            "image2" -> {"รูปภาพ 3", value}
            "image3" -> {"รูปภาพ 4", value}
            "image4" -> {"รูปภาพ 5", value}
            "image5" -> {"รูปภาพ 6", value}
            "image6" -> {"รูปภาพ 7", value}
            "image7" -> {"รูปภาพ 8", value}
            "weight" -> {"น้ำหนัก", value}
            "brand" -> {"แบรนด์", value}
            "country_of_origin" -> {"Country of Origin", value}
            "manufacturer_details" -> {"Manufacturer Details", value}
            _ -> {key, value}
          end
        end)
      end)

    headers = [
      "หมวดหมู่สินค้า",
      "ชื่อสินค้า",
      "รายละเอียดสินค้า",
      "Parent SKU",
      "เลขอ้างอิงตัวเลือกสินค้า",
      "ชื่อตัวเลือก 1",
      "ตัวเลือก 1",
      "ภาพตัวเลือก",
      "ชื่อตัวเลือก 2",
      "ตัวเลือก 2",
      "ราคา",
      "คลังสินค้า",
      "เลข SKU",
      "HS Code",
      "Tax Code",
      "ภาพปก",
      "รูปภาพ 1",
      "รูปภาพ 2",
      "รูปภาพ 3",
      "รูปภาพ 4",
      "รูปภาพ 5",
      "รูปภาพ 6",
      "รูปภาพ 7",
      "รูปภาพ 8",
      "น้ำหนัก",
      "ความยาว",
      "ความสูง",
      "ตัวอย่างช่องทางที่ 1",
      "ตัวอย่างช่องทางที่ 2",
      "ตัวอย่างช่องทางที่ 3",
      "ช่วงระยะเวลาเตรียมพัสดุสำหรับสินค้าพรีออเดอร์",
      "ระยะเวลาเตรียมพัสดุสำหรับสินค้าพรีออเดอร์",
      "แบรนด์",
      "สรรพคุณ (กรอกข้อมูล)",
      "วันหมดอายุ (วันที่)",
      "ความยาวแขน (ตัวเลือกดรอปดาวน์)",
      "ส่วนผสม (ตัวเลือก)",
      "วัตถุดิบ (เลือกได้หลายตัวเลือก)",
      "โอกาสในการใช้งาน (เลือกได้หลายตัวเลือก)",
      "ความจุ (กรอกข้อมูล)",
      "ขนาดหน้าจอ (ตัวเลือก)",
      "ขนาดจอ (ตัวเลือก)",
      "",
      "Country of Origin",
      "Manufacturer Details",
      "Packer Details",
      "Importer Details"
    ]

    sheet = %Sheet{
      name: "Data",
      rows: [
        headers
        | Enum.map(new_data, fn r ->
            Enum.map(headers, fn c ->
              Map.get(r, c)
            end)
          end)
      ],
      row_heights: %{4 => 60}
    }

    workbook = %Workbook{sheets: [sheet]}

    Workbook.append_sheet(%Workbook{}, sheet)
    |> Elixlsx.write_to("data.xlsx")
  end
end
