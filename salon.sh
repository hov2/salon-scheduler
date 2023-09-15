#!/bin/bash

echo -e "\n~~~~~ Salon ~~~~~\n"

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# reset tables
RESET_RESULTS=$($PSQL "TRUNCATE customers, appointments;
ALTER SEQUENCE customers_customer_id_seq RESTART WITH 1;
UPDATE customers set customer_id = DEFAULT;
ALTER SEQUENCE appointments_appointment_id_seq RESTART WITH 1;
UPDATE appointments set appointment_id = DEFAULT;")

SERVICE_MENU() {
  # print any customer support text
  if [[ $1 ]]
    then
      echo -e "\n$1\n"
  fi
  # display services
  echo -e "How may I help you?\n"
  SERVICE_LIST=$($PSQL "select * from services order by service_id;")
  echo "$SERVICE_LIST" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
  done
  read SERVICE_ID_SELECTED
  # check if input is valid
  if [[ ! $SERVICE_ID_SELECTED =~ [1-3] ]]
    then
      # if not valid, send to service menu
      SERVICE_MENU "Please enter a valid input."
    else
      # if valid, get phone number
      echo "What's your phone number?"
      read CUSTOMER_PHONE
      # check if existing customer
      CUSTOMER_NAME=$($PSQL "select name from customers where phone = '$CUSTOMER_PHONE';")
      # if not existing customer
      if [[ -z $CUSTOMER_NAME ]]
        then
        # get new customer name
        echo "I don't have a record for that number. What's your name?"
        read CUSTOMER_NAME
        # insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "insert into customers(phone, name) values('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
      fi
      # get customer_id
      CUSTOMER_ID=$($PSQL "select customer_id from customers where phone = '$CUSTOMER_PHONE'")
      # get service time
      echo "What time would you like?"
      read SERVICE_TIME
      # insert appointment
      INSERT_APPOINTMENT_RESULT=$($PSQL "insert into appointments(customer_id, service_id, time) values('$CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME');")
  fi
  SERVICE_NAME_SELECTED=$($PSQL "select name from services where service_id = '$SERVICE_ID_SELECTED'")
  echo "I have put you down for a $(echo $SERVICE_NAME_SELECTED | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
}

SERVICE_MENU
