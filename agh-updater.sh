#!/bin/bash

interval=0
reattempt_interval=30
exit_on_updatefail=0

## Command Line Args
function help() {
  echo -e "Align your AdGuard Home TLS settings with Træfik"
  echo -e "Usage:"
  echo -e "\t-u <username>\tYour AdGuard Home admin username (for API access)"
  echo -e "\t-p <password>\tYour AdGuard Home admin password (for API access)"
  echo -e "\t-d <domain>\tYour AdGuard Home domain without scheme (e.g. adguard.exmaple.com)"
  echo -e "\t-f <path>\tPath to your traefik cert storage file"
  echo -e "\t-i <seconds>\tInterval between updates (for do once, set to 0)"
  echo -e "\t-e \t\tExit application on any error"
  echo -e "For more, go to https://github.com/willfantom/agh-updater"
}
while getopts heu:p:d:f:i: flag
do
    case "${flag}" in
        i) interval=${OPTARG};;
        e) exit_on_updatefail=1;;
        u) ADGUARD_USERNAME=${OPTARG};;
        p) ADGUARD_PASSWORD=${OPTARG};;
        d) ADGUARD_DOMAIN=${OPTARG};;
        f) TRAEFIK_CERT_JSON=${OPTARG};;
        h) help;exit;;
    esac
done

## Utility Functions
function error() {
  echo "$1 Exiting..."
  if [ $exit_on_updatefail -eq 1 ] || [ $interval -eq 0 ]; then
    exit 1
  fi
}

## Application
if [[ -z "${ADGUARD_USERNAME}" ]]; then
  error "No AdGuard Home admin username is set."
fi
if [[ -z "${ADGUARD_PASSWORD}" ]]; then
  error "No AdGuard Home admin password is set."
fi
if [[ -z "${ADGUARD_DOMAIN}" ]]; then
  error "No AdGuard Home domain is set."
fi
if [[ -z "${TRAEFIK_CERT_JSON}" ]]; then
  error "No Træfik certificate storage file path is set."
fi

credential=$(echo -n "${ADGUARD_USERNAME}:${ADGUARD_PASSWORD}" | base64)

while true; do

  object=$(cat ${TRAEFIK_CERT_JSON} | jq '.'${TRAEFIK_CERT_RESOLVER:-[]}'.Certificates | .[] | select(.domain.main=="'${ADGUARD_DOMAIN}'")')
  certchain64=$(echo -n $object | jq -r .certificate)
  privatekey64=$(echo -n $object | jq -r .key)

  if [ "$certchain64" = "" ]; then
    error "Certificate chain could not be found."
  fi
  if [ "$privatekey64" = "" ]; then
    error "Private key could not be found."
  fi

  echo $(date)
  echo -e "\tFound cert data from Traefik..."
  echo -e "\t\tBase64 Cert Chain (first 25 chars): ${certchain64:0:25}"
  echo -e "\t\tBase64 Private Key (first 25 chars): ${privatekey64:0:25}"


  echo -e "\tCollecting current AdGuard Home TLS settings..."
  currentSettings=$(curl -X GET -s -f -H "Content-Type: application/json" \
    -H "Authorization: Basic $credential" \
    ${ADGUARD_API_SCHEME:-https}://${ADGUARD_DOMAIN}:${ADGUARD_API_PORT:-443}/control/tls/status)
  [ $? -ne 0 ] && error "Request to get current AdGuard Home TLS settings failed." && sleep $reattempt_interval && continue

  updatedSettings=" { \
                      \"server_name\": \"${ADGUARD_DOMAIN}\", \
                      \"certificate_chain\": \"$certchain64\", \
                      \"private_key\": \"$privatekey64\" \
                    }"
  updatedSettings=$(echo "$currentSettings $updatedSettings" | jq -s add)

  echo -e "\tSetting updated AdGuard Home TLS settings..."
  curl -X POST -f -s -o /dev/null -H "Content-Type: application/json" \
    -H "Authorization: Basic $credential" \
    -d "$updatedSettings" \
    ${ADGUARD_API_SCHEME:-https}://${ADGUARD_DOMAIN}:${ADGUARD_API_PORT:-443}/control/tls/configure
  [ $? -ne 0 ] && error "Request to set AdGuard Home TLS settings failed." && sleep $reattempt_interval && continue

  if [ $interval -eq 0 ]; then
    echo "Done"; exit 0
  fi

  sleep $interval

done