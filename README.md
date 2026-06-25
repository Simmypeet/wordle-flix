# wordle_flix

A small terminal Wordle-style game written in [Flix](https://flix.dev/).

The program chooses a random five-letter English word, prompts for guesses, validates each guess against a dictionary API, and prints Wordle-like feedback after each turn:

- green: correct letter in the correct position
- yellow: letter exists in the target word
- gray: letter is not in the target word

Players get six guesses before the target word is revealed.
