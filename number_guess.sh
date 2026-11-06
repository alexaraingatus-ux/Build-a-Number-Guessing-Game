#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME
USERNAME_SQL=$(printf "%s" "$USERNAME" | sed "s/'/''/g")
USER_DATA=$($PSQL "SELECT games_played || ',' || COALESCE(best_game::text, '') FROM users WHERE username = '$USERNAME_SQL'")

if [[ -z $USER_DATA ]]; then
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES ('$USERNAME_SQL', 0, NULL)" > /dev/null
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  IFS=, read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$((RANDOM % 1000 + 1))
NUMBER_OF_GUESSES=0
echo "Guess the secret number between 1 and 1000:"

while read GUESS; do
  if [[ ! $GUESS =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
  if [[ $GUESS == -* ]]; then
    GUESS=$((-10#${GUESS#-}))
  else
    GUESS=$((10#${GUESS#+}))
  fi

  if (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    $PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $NUMBER_OF_GUESSES < best_game THEN $NUMBER_OF_GUESSES ELSE best_game END WHERE username = '$USERNAME_SQL'" > /dev/null
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done