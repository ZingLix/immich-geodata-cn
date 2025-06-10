# 如何生成数据

该文件夹下提供了如下功能的文件：

- data：文件夹下放着对应国家的坐标到地理位置的数据
- enhance_data.py：利用 GeoNames 提供的完整数据去增强 cities500.txt
- generate_geodata_amap.py：利用高德逆地理编码 API 处理 cities500.txt 中对应国家数据，并输出到 data 文件夹下对应 csv
- generate_geodata_nominatim.py：利用 Nominatim API 处理 cities500.txt 中对应国家数据，并输出到 data 文件夹下对应 csv
- prepare_geoname_data.sh：从 GeoNames 下载最新数据的脚本
- release.sh：发布脚本，也是生成数据的脚本，直接运行即可生成所有数据
- translate.py：翻译 geodata 文件
- update.sh：自动更新脚本

需要生成数据的话，直接运行 `bash release.sh` 即可。如果需要定制化生成，可以继续往下看。

## Immich 工作原理

在了解如何生成数据前，需要先了解下 Immich 进行反向地理编码的原理。

> 详细原理可以参见 [这篇文章](https://zinglix.xyz/2025/01/23/immich-reverse-geocoding/)

Immich 进行逆向编码依赖如下文件（在 `/build/geodata` 文件夹中）：

- admin1CodesASCII.txt：一级行政区划列表（`id | name | name ascii | geoname id`）
- admin2Codes.txt：二级行政区划列表（`id | name | name ascii | geoname id`）
- cities500.txt：所有人口大于 500 的城市列表
- geodata-date.txt：数据更新时间
- ne_10m_admin_0_countries.geojson：自然地球国家划分，详细介绍可以 [看这](https://github.com/nvkelso/natural-earth-vector/tree/master)

Immich 会根据照片的经纬度信息，转换成 **国家、省份、城市** 三级，转换流程为：

- 从 cities500.txt 中找到最近的点，拿到他的名称作为 **城市**
- 根据这个点的 admin1Code 信息，去 admin1CodesASCII.txt 文件中找到 **省份** 级别的名称
- 根据这个点的 countryCode，用 [node-i18n-iso-countries](https://github.com/michaelwittig/node-i18n-iso-countries) 转换成 **国家** 级别名称

> 没错，admin2Name 根本没用上，admin2Codes.txt 也没用

因此，要进行汉化，只需要

- 将 cities500.txt 和 admin1CodesASCII.txt 中的名称进行汉化
- 将 [node-i18n-iso-countries](https://github.com/michaelwittig/node-i18n-iso-countries) 库中的数据进行汉化

[Immich 代码](https://github.com/immich-app/immich/blob/1311189fab958bea2177a92e1cc1b7ebb1822bd8/server/src/repositories/map.repository.ts#L131) 中将国家码转换固定写死了转换成 `'en'`，因此只能把 [node-i18n-iso-countries](https://github.com/michaelwittig/node-i18n-iso-countries) 库中的 `en.json` 修改为 `zh.json` 中的中文数据了，修改后的数据 [在这](https://github.com/ZingLix/immich-geodata-cn/blob/main/i18n-iso-countries/langs/en.json)。

## 汉化地理数据

原始的地理位置数据都来自 GeoNames，可以 [在这](https://download.geonames.org/export/dump/) 下载得到。

整体流程如下：

```bash
# 获取最新数据
bash prepare_geoname_data.sh
# 加强原始数据
python enhance_data.py
# 用高德 API 获取国内位置数据
python generate_geodata_amap.py
# 用 nominatim API 获取国外位置数据
LIST=("JP")
for item in "${LIST[@]}"; do
    python generate_geodata_nominatim.py --country-code "$item"
done
# 翻译文件
python translate.py
```

### 汉化 admin1ASCII.txt

> translate_admin1()  translate.py

这一部分数据相对简单且固定，GeoNames 提供了 [alternateNamesV2.zip](https://download.geonames.org/export/dump/alternateNamesV2.zip)，里面包含的是所有地点的别名，只需要找到里面对应地点的中文名进行替换即可。如果遇到繁体，就用 [zhconv](https://github.com/gumblex/zhconv) 进行转换。

当然 alternateNamesV2 里中文名称数据并不完整，但较大的国家目前看数据还比较完整，有更好的汉化思路或者有翻译数据提供，欢迎提 issue 或 PR。

虽然 admin2.txt 没有用上，但也通过该思路进行了汉化。

### 汉化 cities500.txt

> translate_cities500()  translate.py

原始文件中的名称太过于细粒度，很多都到了乡县这一级别，非常不适合查询，因此汉化过程中都统一到了 **国家、一级行政区、二级行政区** 三级，例如

- 中国、四川、成都
- 中国、上海、黄浦（直辖市细化到区）
- 日本、北海道、札幌

这一数据在通过逆位置编码 API 时就可以获取到了，在 `data` 文件夹下保存了所有坐标点和四级行政区的数据，如果需要更改粒度可以在 translate.py 里更换使用的数据级别。

cities500 代表的是人口大于 500 的城市，但国内数据在人口方面不准，也就导致了最后 Immich 中识别出的位置不准。好在 GeoNames 还提供了不同国家的完整数据，可以视情况添加更详细的数据。enhance_data.py 能够读取 ./geoname_data/extra_data 里存在的国家完整数据，并向 cities500.txt 增加人口大于 100 或者特定城市（如直辖市，因为细化到区后粗粒度数据更容易出错）的数据，可以在代码里调整设置。这样，cities500.txt 里就是更加详细的数据。

接下来要做的，就是替换掉 cities500.txt 文件中的第二、第三列数据，遵循如下规则：

- data 文件夹下有的数据，就替换成 **二级行政区** 的名称
- 如果 GeoNames 提供的 alternateNamesV2 中有对应中文名，就替换成该名称
- 从 cities500.txt 中第四列的别名中，如果找到中文名就替换
- 都没有就保持原名

如果是繁体，就用 [zhconv](https://github.com/gumblex/zhconv) 转换成简体。
