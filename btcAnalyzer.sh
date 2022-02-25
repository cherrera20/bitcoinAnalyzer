#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n${redColour}[!] Saliendo...\n${endColor}"

	rm ut.t* money* total_entrada_salida.tmp entradas.tmp salidas.tmp 2>/dev/null
	tput cnorm; exit 1
}

# Variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_transaction_url="https://www.blockchain.com/btc/tx/"
inspect_address_url="https://www.blockchain.com/btc/address/"

function printTable(){

    local -r delimiter="${1}"
    local -r data="$(removeEmptyLines "${2}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines(){

    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString(){

    local -r string="${1}"
    local -r numberToRepeat="${2}"

    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString(){

    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function trimString(){

    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function helpPanel(){
	echo -e "\n${redColour}[!] Uso: ./btcAnalyzer${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-e]${encColour}${yellowColour} Modo exploración${endColour}"
	echo -e "\t\t${purpleColour}unconfirmed_trasactions${endColour}${yelloColour}:\t Listar transacciones no confirmadas${endColour}"
	echo -e "\t\t${purpleColour}inspect${endColour}${yelowColour}:\t\t\t Inspeccionar un hash de transaccións${endColour}"
	echo -e "\t\t${purpleColour}address${endColour}${yelowColour}:\t\t\t Inspeccionar una trasacción de dirección${endColour}"
	echo -e "\n\t${grayColour}[-n]${endColour}${yellowColour}Limitar el número de resultados${endColour}${blueColour} (Ejemplo -n 10)${endColour}"
	echo -e "\n\t${grayColour}[-i]${endColour}${yellowColour}Proporcionar el identificador de transacción.${endColour}${blueColour} (Ejemplo -i ba30wjka0231230213l2212313)${endColour}"
	echo -e "\n\t${grayColour}[-a]${endColour}${yellowColour}Proporcionar una dirección de transacción.${endColour}${blueColour} (Ejemplo -a baasdbasddasdasdasasdasd)${endColour}"
	echo -e "\n\n\t${grayColour}[-h]${encColour}${yellowColour} Mostrar este panel de ayuda${endColour}\n"

	tput cnorm; exit 1

}

function inspectTransaction(){

	inspect_transaction=$1

	echo "Entrada Total_Salida Total" > total_entrada_salida.tmp

	while [ "$(cat total_entrada_salida.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction}" | html2text | grep -E "Total Input|Total Output" -A 1 | grep -v -E "Total Input|Total Output" | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g'  >> total_entrada_salida.tmp
	done

	echo -ne "${grayColour}"
	printTable '_' "$(cat total_entrada_salida.tmp)"
	rm total_entrada_salida.tmp 2>/dev/null


	echo "Dirección (Entradas)_Valor" > entradas.tmp
	while [ "$(cat entradas.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction}" | html2text | grep "Inputs" -A 500 | grep "Outputs" -B 500 | grep "Address" -A 3 | grep -v -E "Address|Value|\--" | awk 'NR%2{printf "%s ", $0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> entradas.tmp
	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat entradas.tmp)"
	echo -ne "${endColour}"
	rm entradas.tmp 2>/dev/null


	echo "Dirección (Salidas)_Valor" > salidas.tmp
	while [ "$(cat salidas.tmp | wc -l)" == "1" ]; do
		curl -s "${inspect_transaction_url}${inspect_transaction}" | html2text | grep "Outputs" -A 500 | grep "thought" -B 500 | grep "Address" -A 3 | grep -v -E "Address|Value|\--" | awk 'NR%2{printf "%s ", $0;next;}1' | awk '{print $1 "_" $2 " " $3}' >> salidas.tmp
	done

	echo -ne "${greenColour}"
	printTable '_' "$(cat salidas.tmp)"
	echo -ne "${endColour}"
	rm salidas.tmp 2>/dev/null

	tput cnorm;
}
function inspectAddress(){
	address_hash=$1
	echo "Transacciones realizadas_Cantitat total recibida (BTC)_Cantidad total enviada (BTC)_Saldo total (BTC)" > address.information

	while [ "$(cat address.information | wc -l)" == "1" ]; do
		curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Transactions|Total Received|Total Sent|Final Balance" -A 1 | grep -v -E "Transactions|Total Received|Total Sent|Final Balance" | head -n -1 | tail -n -4 | xargs | tr ' ' '_' | sed 's/_BTC/ BTC/g' >> address.information
	done

	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"
	rm address.information 2>/dev/null

	bitcoin_value=$(curl -s https://es.finance.yahoo.com/quote/BTC-EUR | html2text | grep "Bitcoin_EUR" -A 1 | tail -n 1 | tr -d '.' | sed 's/\,.*//g')

	echo "Actual Bitcoin value in: $bitcoin_value"

	curl -s "${inspect_address_url}${address_hash}" | html2text | grep "Transactions" -A 1 | head -n -3 | grep -v -E "Transactions" | tail -n 1 > address.information
	curl -s "${inspect_address_url}${address_hash}" | html2text | grep -E "Total Received|Total Sent|Final Balance" -A 1 | grep -v -E "Total Received|Total Sent|Final Balance|\--" > bitcoin_to_eur

	cat bitcoin_to_eur | while read value; do
		valor=$(echo $value | awk '{print $1}' )
		echo "\$$(printf "%'.d\n" "$(echo $valor*$bitcoin_value | bc)" 2>/dev/null)" >> address.information
	done

	line_null=$(cat address.information | grep -n "^\$$" | awk '{print $1}' FS=":")

	if [ $line_null ]; then
		sed "${line_null}s/\$/0.00/" -i address.information
	fi
	
	cat address.information | xargs | tr ' ' '_' >> address.information2
	rm address.information 2>/dev/null
	mv address.information2 address.information
	
	sed '1iTransactions_Total Received (EUR)_Total Sen (EUR)_Final Balance (EUR)' -i address.information
	
	echo -ne "${grayColour}"
	printTable '_' "$(cat address.information)"
	echo -ne "${endColour}"

	rm address.information 2>/dev/null
	tput cnorm
}

function unconfirmedtransactions(){

	echo "Mostrando las primeras $1 lineas"

	number_output=$1

	echo '' > ut.tmp

	while [ "$(cat ut.tmp | wc -l)" == "1" ]; do
		curl -s $unconfirmed_transactions | html2text > ut.tmp
	done
	
	hashes=$(cat ut.tmp | grep "Hash" -A 1 | grep -v -E "Hash|\--|Tiempo" | head -n $number_output)

	echo "Hash_Cantidad_Bitcoin_Tiempo" > ut.table

	for hash in $hashes; do
		echo "${hash}_$(cat ut.tmp | grep "$hash" -A 6 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 4 | tail -n 1)_$(cat ut.tmp | grep "$hash" -A 2 | tail -n 1)" >> ut.table
	done

	cat ut.table | tr '_' ' ' | awk '{print $2}' | grep -v "Cantidad" | sed 's/\,.*//g' | tr -d '.' > money

	money=0; cat money | while read money_in_line; do
		let money+=$money_in_line
		echo $money > money.tmp
	done; 

	echo -n "Cantidad total_ " > amount.table
	echo "\$$(printf "%'.d\n" $(cat money.tmp))" >> amount.table

	if [ "$(cat ut.table | wc -l)" != "1" ]; then
		echo -ne "${yellowColour}"
    	printTable '_' "$(cat ut.table)"
    	echo -ne "${endColour}"
    	echo -ne "${blueColour}"
    	printTable '_' "$(cat amount.table)"
    	echo -ne "${endColour}"
		rm u.* money* amount.table 2>/dev/null
    	tput cnorm; exit 0
	fi

	rm ut.t* money* amount.table 2>/dev/null
	
	tput cnorm;
}

parameter_counter=0; while getopts "e:n:i:a:h" arg; do
	case $arg in
		e) exploration_mode=$OPTARG; let parameter_counter+=1;;
		n) number_output=$OPTARG; let parameter_counter+=1;;
		i) inspect_transaction=$OPTARG; let parameter_counter+=1;;
		a) inspect_address=$OPTARG; let parameter_counter+=1;;
		h) helpPanel;;
	esac
done

tput civis

if [ $parameter_counter -eq 0 ]; then 
	helpPanel

else
	if [ ${exploration_mode} == "unconfirmed_transactions" ] || [ ${exploration_mode} == "ut" ]; then
		if [ ! ${number_output} ]; then
			number_output=100
		fi
		unconfirmedtransactions ${number_output}
	elif [ ${exploration_mode} == "inspect" ]; then
		inspectTransaction $inspect_transaction
	elif [ ${exploration_mode} == "address" ]; then
		inspectAddress $inspect_address
	fi

fi

