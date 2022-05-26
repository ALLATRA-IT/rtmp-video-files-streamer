#!/bin/bash

# Запуск стрима файла с помощью ffmpeg
function startFfmpeg {
  # $1 - file to stream
  # $2 - start_from time
  local file_to_play=$1
  if [ -z "$2" ]
  then
    # Не передали время, начинаем с начала
    local start_from=0
  else
    # Пришло время с которого начинать стрим файла
    local start_from=$2
  fi

  # Без перекодирования
  ffmpeg \
    -re \
    -ss $start_from \
    -i $file_to_play \
    -c copy \
    -f flv $STREAMER_YOUTUBE_LINK

  # Ниже ничего не добавлять, чтобы в результатах был результат работы именно ffmpeg'а
}

# Нужен полный путь к файлу. Относительные ссылки не работают когда скрипт запускает systemctl
source "./.env"

# Генерируем плейлист если он пустой
if [[ -z $(grep '[^[:space:]]' $STREAMER_PLAYLIST_FILE_PATH) ]] ; then
  cp $STREAMER_SOURCE_VIDEO_FILE_PATH $STREAMER_PLAYLIST_FILE_PATH
  echo '[LOG INFO] - New playlist was generated!'
fi

# Берем первый файл из плейлиста
file_to_play=$(head -n 1 $STREAMER_PLAYLIST_FILE_PATH)
date=$(date +%m-%d-%Y-%T)

echo '[LOG INFO] -' $date 'Current file to play: "'$file_to_play'"'

######## Структура файла status.txt ########
#Retries: 0
#Seconds: 60
############################################

# Считываем с какой секунды начать (при ошибке там будет не 0)
seconds_from_status=$(awk 'FNR == 2 {print $2}' "$STREAMER_PROJECT_ROOT_PATH/status.txt")

# Считываем кол-во попыток (при ошибке будет не 0)
retries_from_status=$(awk 'FNR == 1 {print $2}' "$STREAMER_PROJECT_ROOT_PATH/status.txt")

# Засекаем время работы
start_time=$SECONDS
startFfmpeg $file_to_play $seconds_from_status
# После этой команды ничего не надо добавлять, нам надо обработать результат

# Проверяем результат функции (0 - всё ок)
if [ $? -eq 0 ]
then
  # Успешно завершился стрим файла
  # Убираем текущий файл с плейлиста
  sed -i '1d' $STREAMER_PLAYLIST_FILE_PATH

  # Обновляем статус, пишем в файл
  echo -e "Retries: 0 \nSeconds: 0 \n" > "$STREAMER_PROJECT_ROOT_PATH/status.txt"
else
  # Скрипт завершился с ошибкой

  # Отмечаем время остановки с учётом прошлого запуска и за вычетом задержки
  duration=$(( SECONDS - start_time + seconds_from_status - STREAMER_DELAY_SECONDS ))

  # Чтобы не уйти в отрицательные значения при ошибке в самом начале воспроизведения
  if [ $duration -lt 0 ]
  then
    duration=0
  fi

  # Инкрементируем счетчик запусков
  count=$((retries_from_status + 1))

  # Проверяем число запусков, если меньше 10, пробуем ещё раз
  if [ $count -lt $STREAMER_MAX_RETRIES ]
  then
    # Обновляем статус, пишем в файл
    echo -e "Retries: $count \nSeconds: $duration \n" > "$STREAMER_PROJECT_ROOT_PATH/status.txt"

  else
    # Убираем текущий файл с плейлиста
    sed -i '1d' $STREAMER_PLAYLIST_FILE_PATH

    # Обновляем статус, пишем в файл
    echo -e "Retries: 0 \nSeconds: 0 \n" > "$STREAMER_PROJECT_ROOT_PATH/status.txt"

    echo '[LOG INFO] - Retries limit of $count exceeded!'
  fi

fi
