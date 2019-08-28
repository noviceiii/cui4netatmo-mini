#! /bin/sh

set +x
accountfile="account.json"
client_id=`jq -r ".client_id" $accountfile`
client_secret=`jq -r ".client_secret" $accountfile`
username=`jq -r ".username" $accountfile`
password=`jq -r ".password" $accountfile`
device_id=`jq -r ".device_id" $accountfile`
authurl="https://api.netatmo.net/oauth2/token"
tokenfile="token.json"
datafile="data.json"

if [ ! -f $tokenfile ]; then
    echo "Get new access token"
    curl -s -d "grant_type=password&client_id=${client_id}&client_secret=${client_secret}&username=${username}&password=${password}&scope=read_station" "${authurl}" > ${tokenfile}
fi
atoken=`jq -r ".access_token" $tokenfile`
rtoken=`jq -r ".refresh_token" $tokenfile`
expiration=`jq -r ".expires_in" $tokenfile`

filedate=`date "+%Y-%m-%d %H:%M:%S" -r $tokenfile`
#filedate=${filedate/_/ }
filedate=`date -d "$filedate" +%s`
limittime=`expr $filedate + $expiration`
currenttime=`date +%s`

if [ $limittime -lt $currenttime ]; then
    echo "Using refresh token"
    curl -s -d "grant_type=refresh_token&refresh_token=${rtoken}&client_id=${client_id}&client_secret=${client_secret}" "${authurl}" > $tokenfile
    atoken=`jq -r ".access_token" $tokenfile`
fi

curl -s -d "access_token=${atoken}&device_id=${device_id}" "https://api.netatmo.net/api/getstationsdata" > $datafile

pres=`jq -r ".body.devices[0].dashboard_data.Pressure" $datafile`
extemp=`jq -r ".body.devices[0].modules[0].dashboard_data.Temperature" $datafile`
exhumi=`jq -r ".body.devices[0].modules[0].dashboard_data.Humidity" $datafile`
exrain=`jq -r ".body.devices[0].modules[1].dashboard_data.Rain" $datafile`
exwind=`jq -r ".body.devices[0].modules[2].dashboard_data.WindStrength" $datafile`
exgust=`jq -r ".body.devices[0].modules[2].dashboard_data.GustStrength" $datafile`

echo "$extemp °C | Humidit: $exhumi % | Rain: $exrain mm | Wind: $exwind (Gust $exgust) m/s | $pres hPa"
