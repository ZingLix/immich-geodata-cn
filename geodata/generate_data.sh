#!/bin/bash

set -e

# 设置时间格式和文件名
CURRENT_DATE=${CURRENT_DATE:-$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")}
TODAY_DATE=${TODAY_DATE:-$(date -u +"%Y-%m-%d")}

CN_PATTERN="{admin_2}"
FULL=false
OUTPUT_FOLDER="./output_tmp"
OUTPUT_FILE="./output/geodata.zip"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cn-pattern)
      CN_PATTERN="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --full)
      FULL=true
      shift
      ;;
    *)
      echo "未知参数: $1"
      exit 1
      ;;
  esac
done

rm -rf $OUTPUT_FOLDER

FULL_ARGS=""
if [ "$FULL" = true ]; then
  FULL_ARGS=" --full"
fi

# 运行 python enhance_data.py
echo "运行 python enhance_data.py..."
python enhance_data.py $FULL_ARGS --output ./geoname_data/cities500.txt.tmp

# 运行 python generate_geodata_amap.py
echo "运行 python generate_geodata_amap.py..."
python generate_geodata_amap.py --data-file ./geoname_data/cities500.txt.tmp

if [ "$FULL" = true ]; then
  echo "运行额外数据 python generate_geodata_amap.py..."
  python generate_geodata_amap.py --data-file ./geoname_data/extra_data/CN.txt
  python generate_geodata_amap.py --data-file ./geoname_data/extra_data/MO.txt --country-code MO
  python generate_geodata_amap.py --data-file ./geoname_data/extra_data/HK.txt --country-code HK
fi

# 准备列表并运行 generate_geodata_nominatim.py
LIST=("TW")
for item in "${LIST[@]}"; do
    echo "运行 python generate_geodata_nominatim.py $item..."
    python generate_geodata_nominatim.py --country-code "$item" --data-file ./geoname_data/extra_data/$item.txt
    if [[ $? -ne 0 ]]; then
        echo "运行 python generate_geodata_nominatim.py $item 失败！退出。"
        exit 1
    fi
done

# 准备列表并运行 generate_geodata_nominatim.py
LIST=("JP")
for item in "${LIST[@]}"; do
    echo "运行 python generate_geodata_nominatim.py $item..."
    python generate_geodata_nominatim.py --country-code "$item"
    if [[ $? -ne 0 ]]; then
        echo "运行 python generate_geodata_nominatim.py --country-code $item 失败！退出。"
        exit 1
    fi
done

rm -rf "$OUTPUT_FOLDER"
mkdir -p "$OUTPUT_FOLDER"

echo "运行 python translate.py..."
python translate.py --cn-pattern "$CN_PATTERN" --output "$OUTPUT_FOLDER" --input-cities500 ./geoname_data/cities500.txt.tmp
if [[ $? -ne 0 ]]; then
    echo "运行 python translate.py 失败！退出。"
    exit 1
fi


# 复制 geojson 文件到 output 文件夹
echo "复制 geoname_data/ne_10m_admin_0_countries.geojson 到 output 文件夹..."
mkdir -p output
cp geoname_data/ne_10m_admin_0_countries.geojson $OUTPUT_FOLDER
if [[ $? -ne 0 ]]; then
    echo "复制 geojson 文件失败！退出。"
    exit 1
fi

# 创建 geodata-date.txt 文件
echo "创建 geodata-date.txt 文件..."
echo "$CURRENT_DATE" > "$OUTPUT_FOLDER/geodata-date.txt"

# 打包 output 文件夹
ZIP_FILE="$OUTPUT_FILE"
echo "打包 output 文件夹为 $ZIP_FILE..."
rm -rf geodata
mv "$OUTPUT_FOLDER" geodata
zip -r "$ZIP_FILE" geodata/
if [[ $? -ne 0 ]]; then
    echo "打包文件失败！退出。"
    exit 1
fi

echo "脚本执行完成！打包文件：$ZIP_FILE"