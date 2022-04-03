<p align="center">
  <a href="https://github.com/oxystin/duplicati-notify-to-telegram"><img src="https://raw.githubusercontent.com/oxystin/duplicati-notify-to-telegram/main/img/notify_to_telegram.png" width="830"></a>
</p>

<span align="center">

# Duplicati Notify to Telegram
[![GitHub all releases](https://img.shields.io/github/downloads/oxystin/duplicati-notify-to-telegram/total)](https://github.com/oxystin/duplicati-notify-to-telegram/releases)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/oxystin/duplicati-notify-to-telegram.svg)](https://github.com/oxystin/duplicati-notify-to-telegram/pulls)
[![GitHub issues](https://img.shields.io/github/issues/oxystin/duplicati-notify-to-telegram.svg)](https://github.com/oxystin/duplicati-notify-to-telegram/issues)

Script for receiving notifications in telegram about the results of Duplicati backup

</span>

## Installation:

Duplicati is able to run scripts before and after backups. This functionality is available in the advanced options of any backup job (UI) oras option (CLI). The (advanced) options to run scripts are   
`--run-script-before = /script/notify_to_telegram.sh`   
`--run-script-after = /script/notify_to_telegram.sh`

To work, you need to set two required variables: 
- TELEGRAM_TOKEN
- TELEGRAM_CHATID

These variables can be set directly in the script file or set as environment variables. If you are using docker you can use the following example to automatically install the script in the `/script/notify_to_telegram.sh` folder and set the environment variables:

```yaml
version: "3"
services:
  duplicati:
    image: linuxserver/duplicati:2.0.6
    container_name: duplicati
    entrypoint: >
          sh -c "mkdir -p /script &&
          if [ ! -f /script/notify_to_telegram.sh ]; then
            curl -s `printenv SCRIPT_URL` -o /script/notify_to_telegram.sh
          fi &&
          chown -R 1000:1000 /script &&
          chmod -R 744 /script && 
          /init"
    environment:
      - PUID=0
      - PGID=0
      - TZ=Europe/Berlin
      - TELEGRAM_TOKEN=<YOUR TELEGRAM TOKEN>
      - TELEGRAM_CHATID=<YOUR TELEGRAM CHAT ID>
      - SCRIPT_URL=https://raw.githubusercontent.com/oxystin/duplicati-notify-to-telegram/main/notify_to_telegram.sh
    volumes:
      - </path/to/config>:/config
      - </path/to/script>:/script
      - </path/to/backups>:/backups
      - </path/to/source>:/source
    ports:
      - 8200:8200
    restart: unless-stopped
```