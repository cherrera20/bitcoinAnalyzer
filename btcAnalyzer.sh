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

	tput cnorm; exit 1
}

# Variables globales
unconfirmed_transactions="https://www.blockchain.com/es/btc/unconfirmed-transactions"
inspect_trasaction_url="https://www.blockchain.com/es/btc/tx/"
inspect_address_url="https://www.bloackchain.com/es/btc/address"

function helpPanel(){
	echo -e "\n${redColour}[!] Uso: ./btcAnalyzer${endColour}"
	for i in $(seq 1 80); do echo -ne "${redColour}-"; done; echo -ne "${endColour}"
	echo -e "\n\n\t${grayColour}[-e]${encColour}${yellowColour} Modo exploración${endColour}"

}

while getopts "e:h" arg; do
	case $arg in
		e) exploration_mode=$OPTARG;;
		h) helpPanel;;
	esac
done


