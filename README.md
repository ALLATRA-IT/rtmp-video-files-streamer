### Настройка сервера

Устанавливаем ffmpeg  
`sudo snap install ffmpeg`

1. Копируем скрип в системные сервисы  
   `sudo cp ffmpeg-streamer.service /etc/systemd/system/ffmpeg-streamer.service`

2. Перезагружаем сервис systemd  
   `sudo systemctl daemon-reload`

3. Добавляем созданный юнит в автозагрузку  
   `sudo systemctl enable ffmpeg-streamer.service`

4. Запускаем сервис  
   `sudo systemctl start ffmpeg-streamer`


## Полезные команды

Просмотр сколько времени стримится текущее видео:  
`ps -eo pid,comm,cmd,start,etime | grep ffmpeg`

Информация о статусе юнита:

`sudo systemctl status ffmpeg-streamer`

Релоад конфигурации демона:

`sudo systemctl reload ffmpeg-streamer`

Логи определенного юнита (сразу последняя страница -e):

`sudo journalctl -e -u ffmpeg-streamer`

Следить (tail -f) за логом определенного юнита:

`sudo journalctl -f -u ffmpeg-streamer`

Сохранить весь лог в один файл:
`sudo journalctl -u ffmpeg-streamer --no-pager > out.log.txt`
