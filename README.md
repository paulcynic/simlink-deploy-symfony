## Инструкция

1. Зайти на виртуальную машину 
2. Закачать два файла: `symfony.conf` и `switch_simlink.sh` в домашнюю директорию
3. (Только для этой виртуальной машины:)
  - подменить конфиг `nginx`
  - для этого нужно один раз выполнить закомментированные в файле `switch_simlink.sh` скрипты
4. Запустить файл `switch_simlink.sh` где аргументом является версия приложения. Например:
```
~$ ./switch_simlink.sh v1.6.4
```
или
```
~$ ./switch_simlink.sh v1.8.0
```
5. По умолчанию разворачивается последняя, более поздняя версия. Чтобы запустить более раннюю версию, нужно удалить директорию `staging`.
