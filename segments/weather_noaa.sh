#!/usr/bin/env bash
# Prints the current weather in Celsius, Fahrenheits or lord Kelvins. The forecast is cached and updated with a period of $update_period.

# You location. Find a code that works for you:
# 1. Go to Yahoo weather http://weather.yahoo.com/
# 2. Find the weather for you location
# 3. Copy the last numbers in that URL. e.g. "http://weather.yahoo.com/united-states/california/newport-beach-12796587/" has the number "12796587"
location="KSEA"

# Can be any of {c,f,k}.
unit="f"

# The update period in seconds.
update_period=600

# Cache file.
tmp_file="${tp_tmpdir}/weather_noaa_${location}.txt"


degree=""
# Get symbol for condition. Available conditions: http://developer.yahoo.com/weather/#codes
get_condition_symbol() {
	local condition=$(echo "$1" | tr '[:upper:]' '[:lower:]')
	case "$condition" in
	"sunny" | "hot")
		hour=$(date +%H)
		if [ "$hour" -ge "22" -o "$hour" -le "5" ]; then
			#echo "☽"
			echo "☾"
		else
			#echo "☀"
			echo "☼"
		fi
		;;
	"rain" | "light rain" | 'Light Rain' | "mixed rain and snow" | "mixed rain and sleet" | "freezing drizzle" | "drizzle" | "freezing rain" | "showers" | "mixed rain and hail" | "scattered showers" | "isolated thundershowers" | "thundershowers")
			# echo "☂"
			echo "☔"
		;;
	"snow" | "mixed snow and sleet" | "snow flurries" | "light snow showers" | "blowing snow" | "sleet" | "hail" | "heavy snow" | "scattered snow showers" | "snow showers")
			#echo "☃"
			echo "❅"
		;;
	"cloudy" | "mostly cloudy" | "partly cloudy")
		echo "☁"
		;;
	"tornado" | "tropical storm" | "hurricane" | "severe thunderstorms" | "thunderstorms" | "isolated thunderstorms" | "scattered thunderstorms")
			#echo "⚡"
			echo "☈"
		;;
	"dust" | "foggy" | "fog" | "haze" | "smoky" | "blustery" | "mist")
		#echo "♨"
		#echo "﹌"
		echo "〰"
		;;
	"windy")
		#echo "⚐"
		echo "⚑"
		;;
	"clear" | "fair" | "cold")
		#echo "✈"    # So clear you can see the aeroplanes!
		echo "☀"
		#echo "☼"
		;;
	*)
		echo "？"
		;;
	esac
}

read_tmp_file() {
	if [ ! -f "$tmp_file" ]; then
		return
	fi

	regex="/T(\d{1})(\d{3})(\d{1})(\d{3})/"

	METAR=`cat $tmp_file`
	SYMBOLS=''
	for line in ${METAR}
	do
		# if [[ ${line} =~ ^[0-9]{2}/[0-9]{2}$ ]]; then

			# degree=32
		if [[ ${line} =~ ^T[0-9]{8}$ ]]; then
			TEMP=${line:2:3}
			SIGN=${line:1:1}
			TMP=`awk -v temp=${TEMP} 'BEGIN {print temp / 10}'`
			if [[ "${SIGN}" == "1" ]]; then
				TMP=`echo "${TMP} * -1" | bc`
			fi
			degree=$(echo "${TMP} * 1.8 + 32" | bc)
			# http://www.fileformat.info/info/unicode/category/Sm/list.htm
			# clr: 〇
			# few: ⦵ ⊝ ⊖
			# sct: ⦶ ⌽
			# bkn: ⊜ ⊜
			# ovc: ⊕ ⊕
			# vv:  ⦻ ⊗
		elif [[ ${line} =~ ^(FEW|SCT|BKN|OVC|VV)[0-9]{3}$ ]]; then
			HEIGHT=${line/[A-Z][A-Z][A-Z]/}
			theRest=${line/${HEIGHT}/}
			theRest=${theRest/FEW/⊝}
			theRest=${theRest/SCT/⌽}
			theRest=${theRest/BKN/⊜}
			theRest=${theRest/OVC/⊕}
			theRest=${theRest/VV/⊗}
			SYMBOLS+=${HEIGHT}${theRest}" "
		fi
	done
	condition_symbol="${SYMBOLS}"
}


function shouldGetNewFile() {
	if [ "$PLATFORM" == "mac" ]; then
		last_update=$(stat -f "%m" ${tmp_file})
	else
		last_update=$(stat -c "%Y" ${tmp_file})
	fi
	time_now=$(date +%s)

	up_to_date=$(echo "(${time_now}-${last_update}) < ${update_period}" | bc)
	echo $up_to_date
}

if [ shouldGetNewFile -eq 1 ]; then
	read_tmp_file
else
	weather_data=$(curl --max-time 4 -s "http://weather.noaa.gov/pub/data/observations/metar/stations/${location}.TXT")
	echo "$weather_data" > $tmp_file
	read_tmp_file
fi

if [ -n "$degree" ]; then
	if [ "$unit" == "k" ]; then
		degree=$(echo "${degree} + 273.15" | bc)
	fi
	unit_upper=$(echo "$unit" | tr '[cfk]' '[CFK]')
	# condition_symbol=$(get_condition_symbol "$condition")
	echo "${condition_symbol}${degree}°${unit_upper}"
fi
