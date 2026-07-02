#!/bin/bash

set -e

# 定义目标文件夹和URL
TARGET_DIR="geoname_data"
ZIP_FILE="$TARGET_DIR/cities500.zip"
TXT_FILE="$TARGET_DIR/cities500.txt"
ADMIN1_FILE="$TARGET_DIR/admin1CodesASCII.txt"
ADMIN2_FILE="$TARGET_DIR/admin2Codes.txt"
GEOJESON_FILE="$TARGET_DIR/ne_10m_admin_0_countries.geojson"
EXTRA_DATA_DIR="$TARGET_DIR/extra_data"
DOWNLOAD_URL="https://download.geonames.org/export/dump/cities500.zip"
# 需要增加全量数据的地区列表
LIST=("CN" "HK" "TW" "MO")

if [[ "$1" == "--update" ]]; then
    if [[ -d "$TARGET_DIR" ]]; then
        echo "检测到 --update 参数，删除文件夹 $TARGET_DIR ..."
        rm -rf "$TARGET_DIR"
        echo "文件夹 $TARGET_DIR 已删除。"
    else
        echo "文件夹 $TARGET_DIR 不存在，无需删除。"
    fi
    exit 0
fi

# 创建目标文件夹
mkdir -p "$TARGET_DIR"

# 下载文件
echo "正在下载 $DOWNLOAD_URL 到 $ZIP_FILE..."
curl -o "$ZIP_FILE" "$DOWNLOAD_URL"

# 检查下载是否成功
if [[ $? -ne 0 ]]; then
  echo "下载失败，请检查网络连接或URL是否正确。"
  exit 1
fi

mkdir -p "$EXTRA_DATA_DIR"

for item in "${LIST[@]}"; do
    echo "下载额外数据 $item..."
    curl -o "$EXTRA_DATA_DIR/$item.zip" "https://download.geonames.org/export/dump/$item.zip"
    if [[ $? -ne 0 ]]; then
        echo "下载 $item.zip 失败！退出。"
        exit 1
    fi
    unzip -o "$EXTRA_DATA_DIR/$item.zip" -d "$EXTRA_DATA_DIR"

    # 移动解压后的文件
    if [[ -f "$EXTRA_DATA_DIR/$item.txt" ]]; then
      echo "解压 $item.zip 成功"
    else
      echo "未找到 $item.txt，请检查解压结果。"
      exit 1
    fi

    # 删除中间文件
    rm -f "$EXTRA_DATA_DIR/$item.zip"
done

rm -f "$EXTRA_DATA_DIR/readme.txt"

echo "正在下载 $ADMIN1_FILE..."
curl -o "$ADMIN1_FILE" "https://download.geonames.org/export/dump/admin1CodesASCII.txt"

# 检查下载是否成功
if [[ $? -ne 0 ]]; then
  echo "下载失败，请检查网络连接或URL是否正确。"
  exit 1
fi

# 下载文件
echo "正在下载 $ADMIN2_FILE..."
curl -o "$ADMIN2_FILE" "https://download.geonames.org/export/dump/admin2Codes.txt"

# 检查下载是否成功
if [[ $? -ne 0 ]]; then
  echo "下载失败，请检查网络连接或URL是否正确。"
  exit 1
fi

# 下载文件
echo "正在下载 $GEOJESON_FILE..."
curl -o "$GEOJESON_FILE" "https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_admin_0_countries.geojson"

# 检查下载是否成功
if [[ $? -ne 0 ]]; then
  echo "下载失败，请检查网络连接或URL是否正确。"
  exit 1
fi

echo "下载成功，解压缩中..."

# 解压缩文件到目标目录
unzip -o "$ZIP_FILE" -d "$TARGET_DIR"

# 移动解压后的文件
if [[ -f "$TARGET_DIR/cities500.txt" ]]; then
  echo "解压成功，将 cities500.txt 移动到目标目录。"
else
  echo "未找到 cities500.txt，请检查解压结果。"
  exit 1
fi

# 删除中间文件
echo "清理中间文件..."
rm -f "$ZIP_FILE"

echo "操作完成！cities500.txt 已放置于 $TARGET_DIR 目录下。"



# 设置下载的zip文件名和目标txt文件名
ZIP_FILE="$TARGET_DIR/alternateNamesV2.zip"
TXT_FILE="$TARGET_DIR/alternateNamesV2.txt"
DOWNLOAD_URL="https://download.geonames.org/export/dump/alternateNamesV2.zip" # 替换为实际的下载链接

# 检查是否已存在目标txt文件
if [[ -f "$TXT_FILE" ]]; then
    echo "目标文件 $TXT_FILE 已存在，不需要下载。"
    exit 0
fi

# 如果zip文件存在，则直接解压
if [[ -f "$ZIP_FILE" ]]; then
    echo "$ZIP_FILE 已存在"
else
    # 下载zip文件
    echo "正在下载 $ZIP_FILE ..."
    curl -o "$ZIP_FILE" "$DOWNLOAD_URL"
    if [[ $? -ne 0 ]]; then
        echo "下载失败，退出。"
        exit 1
    fi
fi

# 解压zip文件
echo "正在解压 $ZIP_FILE ..."
unzip -o "$ZIP_FILE" -d "$TARGET_DIR"
if [[ $? -eq 0 ]]; then
    echo "解压完成，删除 $ZIP_FILE ..."
    #rm -f "$ZIP_FILE"
else
    echo "解压失败。"
    exit 1
fi