Лабораторная работа по настройке nginx (reverse-)proxy сервера
====

Полностью задание звучит так:
>Необходимо настроить прокси-сервер на базе nginx для проксирования домена test-admin.local.net с внешнего сервера 192.168.1.50 на внутренний сервер 192.168.1.60.
>Внешний сервер должен принимать соединения на 80 и 443 порты, далее проксировать необходимый домен только на 443 порт внутреннего сервера. Подключения на 443 порты по ssl.
>Проксирование должно быть ПРОЗРАЧНЫМ, т.е. настроено таким образом, чтобы: для бекэнда входящий запрос не отличался от такого же запроса отправленного клиентом напрямую в бекэнд, а для клиента не было возможности каким-то образом определить, что его запрос куда-то и каким-то образом проксировался.
>В качестве решения задачи необходимо предоставить конфиг прокси-сервера на базе nginx.
>Какие-либо условия, которые явно не указаны в задаче, но по вашему мнению могут иметь значение для выбора того или иного решения, вы можете предполагать на свое усмотрение, сопроводив решение соответствующими комментариями.

В данной работе дополнительно используется docker-compose.nginx.yml файл, в котором настроены 4 сервиса:
- nmt1 - реверс-прокси
- nmt2 - backend
- nmt3 - тестовый хост, с которого моделируются обращения напрямую в backend  
все эти три сервиса запускаются на базе легковесного образа nginx:stable-alpine
- certs - сервис на базе stakater/ssl-certs-generator:1.0 - используется для (пере)выпуска самоподписанных ssl-сертификатов (по условию задачи - к домену test-admin.local.net)

Для запуска окружения нужно выполнить команду
~~~
docker-compose -f docker-compose.nginx.yml up -d
~~~
Сгенерируются сертификаты и будет возможно тестирование.  
Для тестирования реверс-прокси необходимо на любой машине, у которой есть сетевой доступ 443/tcp 80/tcp к машине, на которой запущен docker-compose прописать в /etc/hosts запись для доменного имени test-admin.local.net  
На самой этой машине это можно сделать прописав в качестве адреса localhost  
Так же можно настроить эту запись в локальной dns-зоне, если такая имеется.

Для тестирования реверс-прокси необходимо выполнить команду с внешней машины или из консоли хоста, на котором запущен docker-compose
~~~
curl -s http://test-admin.local.net
~~~
Для тестирования ssl сертификата необходимо скопировать сертификат удостоверяющего центра командой
~~~
docker cp nmt1:/certs/ca.pem ./
~~~
После чего обратиться к хосту по 443 порту:
~~~
curl --cacert ca.pem -s https://test-admin.local.net
~~~
В любом случае ответом будет тот, который нам отдаёт backend на 443 порту.

Проверим, как отвечает backend если обратиться к нему напрямую, то есть из его локальной сети, для чего используем контейнер nmt3 и скопированый в него скрипт test1.sh  
Будем изменять в /etc/hosts контейнера nmt3 айпи адрес для test-admin.local.net и после чего запрашивать curl на 80 и 443 порты.  
В случае обращения к реверс-прокси нам ответят на обоих портах одинаково, в случае обращения к бэкенду ответ будет только один, так как 80 порт на бэкенде не слушается.

Для автоматической замены /etc/hosts в контейнере nmt3 и запуске тестов подготовлен скрипт test.sh который нужно заупскать на хосте с докером:
~~~
./test.sh nmt1
~~~
- эта комана аналогична команде указанной выше, так как происходит обращение с nmt3 на реверс-прокси
~~~
./test.sh nmt2
~~~
- эта команда тестирует обращения с nmt3 на бэкенд по 80 и 443 портам.

Если необходимо протестировать доступность бэкенда отдельно со стороны хоста - нужно закомментировать в docker-compose.nginx.yml для сервиса nmt2 директиву expose и раскомментировать ports.  
После чего перезапустить контейнеры и можно обращаться к бэкенду с хоста через localhost:44443
