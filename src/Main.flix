use Net.Body
use Net.HttpResponse
use Net.Http
use Sys.Console

enum Render with Eq {
    case Green
    case Yellow
    case Gray
}

eff IsWord {
    def isWord(word: String): Bool
}

def check(guess: Vector[Char], expected: Vector[Char]): Vector[Render] = {
    Vector.zip(guess, expected)
        |> Vector.map(
            match (g, e) ->
                if (g == e) {
                    Render.Green
                } else if (expected |> Vector.memberOf(g)) {
                    Render.Yellow
                } else {
                    Render.Gray
                }
        )
}

def printRender(render: Vector[Render], guess: Vector[Char]): Unit \ Console =
    foreach ((r, g) <- Vector.zip(render, guess)) {
        Sys.Console.print("${g}");

        match r {
            case Render.Green  => Sys.Console.print("🟩 ")
            case Render.Yellow => Sys.Console.print("🟨 ")
            case Render.Gray   => Sys.Console.print("⬜️ ")
        }
    }

def getRandomWord(): Result[IoError, Vector[Char]] \ Http = {
    forM (res <- Http.get("https://random-word-api.herokuapp.com/word?length=5"))
        yield {
            match res {
                case HttpResponse({body = Body.Text(text) | _}) =>
                    text |> String.toVector
                case HttpResponse({body = Body.Bytes(text) | _}) =>
                    text |> String.fromBytes |> String.toVector
            } |> Vector.slice(start = 2, end = 7)
        }
}

def isWord(word: String): Result[IoError, Bool] \ Http = {
    forM (res <- Http.get("https://api.dictionaryapi.dev/api/v2/entries/en/${word}"))
        yield {
            match res {
                case HttpResponse({status = 200 | _}) => true
                case _                                => false
            }
        }
}

def getGuess(): Vector[Char] \ Console + IsWord = {
    Console.print("Enter a 5 letter word: ");
    let input = Console.readln()
        |> Option.map(String.trim)
        |> Option.map(String.toLowerCase);

    match input {
        case Some(text) => if (String.length(text) == 5) {
            if (IsWord.isWord(text)) {
                text
                    |> String.toVector
            } else {
                Console.println("That's not a valid word.");
                getGuess()
            }
        } else {
            Console.println("Please enter a 5 letter word.");
            getGuess()
        }

        case None => {
            Console.println("Try again brother");
            getGuess()
        }
    }
}

def playTurn(currentRender: List[(Vector[Render], Vector[Char])], goal: Vector[Char]): Unit \ Console + IO + IsWord = {
    // clear screen
    Console.print(
        Vector#{27i8, 91i8, 50i8, 74i8, 27i8, 91i8, 49i8, 59i8, 49i8, 72i8} |> String.fromBytes
    );

    foreach ((r, g) <- currentRender) {
        printRender(r, g); println("")
    };

    if (currentRender |> List.length == 6) {
        let goalString = Vector.foldLeft((s, c) -> "${s}${c}", "", goal);
        Console.println("You lost! The word was: ${goalString}")
    } else {
        let guess = getGuess();
        let render = check(guess, goal);

        if (render |> Vector.forAll(r -> r == Render.Green)) {
            Console.println("You won!")
        } else {
            playTurn(currentRender ++ ((render, guess) :: Nil), goal)
        }
    }
}

def turn(): Unit \ Http + Console + IO = {
    run {
        match getRandomWord() {
            case Ok(word) => playTurn(Nil, word)
            case Err(err) => {
                Console.println("That's too bad, something went wrong: " + err.toString())
            }
        }
    } with handler IsWord {
        def isWord(w, k) = {
            match isWord(w) {
                case Ok(result) => k(result)
                case Err(err) => {
                    Console.println("That's too bad, something went wrong: " + err.toString())
                }
            }
        }
    }
}

def main(): Unit \ Http + Console + IO = {
    turn()
}
