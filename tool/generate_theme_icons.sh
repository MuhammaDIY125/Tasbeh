#!/usr/bin/env bash
# Генерирует значки приложения для тем из ThemePalette (lib/theme_cubit.dart).
#
# Знак «33» берётся из assets/icon.png и assets/icon_foreground.png как есть —
# меняются только цвета: фон — цвет темы, цифры — белые на тёмных темах и
# почти чёрные на светлых. Основной значок (чёрная тема) по-прежнему
# генерирует flutter_launcher_icons, этот скрипт его не трогает.
#
# Запускать из корня проекта после изменения цветов тем или самого значка.
# Нужен ffmpeg.
set -euo pipefail

# Тема, фон, цвет цифр. Цвета фона — те же, что в ThemePalette.
THEMES=(
  "graphite    22262A FFFFFF"
  "midnight    172338 FFFFFF"
  "emerald     112A1D FFFFFF"
  "pomegranate 39191B FFFFFF"
  "white       F5F5F2 1C1C1C"
  "sand        EFE5D4 1C1C1C"
  "sage        DBE4D9 1C1C1C"
)

# Тёмные цифры для светлых тем: #1C1C1C — цвет текста светлой темы.
DARK_INK=28

ANDROID_RES=android/app/src/main/res
IOS_ASSETS=ios/Runner/Assets.xcassets
DENSITIES=("mdpi 48" "hdpi 72" "xhdpi 96" "xxhdpi 144" "xxxhdpi 192")

ffmpeg_quiet() { ffmpeg -v error -y "$@"; }

# Перекрашивает белый знак на чёрном: чёрное становится фоном, белое —
# цифрами, а сглаженные края — точной смесью двух цветов.
recolor_expr() {
  local bg=$1 fg=$2 expr="" channel i
  for i in 0 2 4; do
    local b=$((16#${bg:i:2})) f=$((16#${fg:i:2}))
    case $i in 0) channel=r ;; 2) channel=g ;; *) channel=b ;; esac
    expr+="${channel}='${b}+(${f}-${b})*val/255':"
  done
  echo "lutrgb=${expr%:}"
}

capitalize() { echo "$(tr '[:lower:]' '[:upper:]' <<<"${1:0:1}")${1:1}"; }

# Цифры адаптивного значка для светлых тем: тот же слой переднего плана,
# перекрашенный в тёмный с сохранением прозрачности.
for density in "${DENSITIES[@]}"; do
  read -r name _ <<<"$density"
  ffmpeg_quiet -i "$ANDROID_RES/drawable-$name/ic_launcher_foreground.png" \
    -vf "format=rgba,lutrgb=r=$DARK_INK:g=$DARK_INK:b=$DARK_INK" \
    "$ANDROID_RES/drawable-$name/ic_launcher_foreground_dark.png"
done

colors="<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!-- Сгенерировано tool/generate_theme_icons.sh. -->
<resources>"

for theme in "${THEMES[@]}"; do
  read -r name bg fg <<<"$theme"
  foreground=ic_launcher_foreground
  [[ $fg != FFFFFF ]] && foreground=ic_launcher_foreground_dark
  colors+="
    <color name=\"ic_launcher_background_$name\">#$bg</color>"

  cat >"$ANDROID_RES/mipmap-anydpi-v26/ic_launcher_$name.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<!-- Сгенерировано tool/generate_theme_icons.sh. -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background_$name"/>
  <foreground>
      <inset
          android:drawable="@drawable/$foreground"
          android:inset="16%" />
  </foreground>
  <monochrome>
      <inset
          android:drawable="@drawable/ic_launcher_monochrome"
          android:inset="16%" />
  </monochrome>
</adaptive-icon>
EOF

  # Обычные значки — для Android 7, где адаптивных ещё нет.
  for density in "${DENSITIES[@]}"; do
    read -r density_name size <<<"$density"
    ffmpeg_quiet -i assets/icon.png \
      -vf "format=rgb24,$(recolor_expr "$bg" "$fg"),scale=$size:$size:flags=lanczos" \
      "$ANDROID_RES/mipmap-$density_name/ic_launcher_$name.png"
  done

  # iOS: один значок 1024×1024, остальные размеры Xcode нарежет сам.
  iconset="$IOS_ASSETS/AppIcon-$(capitalize "$name").appiconset"
  mkdir -p "$iconset"
  ffmpeg_quiet -i assets/icon.png \
    -vf "format=rgb24,$(recolor_expr "$bg" "$fg")" "$iconset/icon.png"
  cat >"$iconset/Contents.json" <<EOF
{
  "images" : [
    {
      "filename" : "icon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
done

echo "$colors
</resources>" >"$ANDROID_RES/values/ic_launcher_theme_colors.xml"

echo "Готово: ${#THEMES[@]} тем."
