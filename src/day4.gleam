import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

fn get_s_at(lines: List(String), x, y) {
  let mx = lines |> list.length
  case x < 0 || x >= mx || y < 0 || y >= mx {
    True -> " "
    False -> {
      case list.first(list.drop(lines, y)) {
        Ok(line) -> {
          case string.first(string.drop_start(line, x)) {
            Ok(c) -> c
            Error(_) -> " "
          }
        }
        Error(_) -> " "
      }
    }
  }
}

fn is_word_at(lines, x, y, dx, dy, word) {
  let word_length = list.range(0, string.length(word) - 1)
  let maybe_xmas = word_length |> list.map(fn(i) {
    get_s_at(lines, x + i * dx, y + i * dy)
  }) |> string.concat
  case maybe_xmas == word {
    True -> 1
    False -> 0
  }
}

fn are_words_at(lines, x, y, word) {
  let w1 = is_word_at(lines, x-1, y+1, 1, -1, word)
  let w1r = is_word_at(lines, x+1, y-1, -1, 1, word)
  let w2 = is_word_at(lines, x-1, y-1, 1, 1, word)
  let w2r = is_word_at(lines, x+1, y+1, -1, -1, word)
  case {{w1 == 1 || w1r == 1} && {w2 == 1 || w2r == 1}} {
    True -> 1
    False -> 0
  }
}

fn read_file_day4(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  let vectors = [
    #(1, 0), #(-1, 0),
    #(0, 1), #(0, -1),
    #(1, 1), #(-1, -1),
    #(-1, 1), #(1, -1),
  ]
  let line_range = list.range(0, list.length(lines) - 1)
  list.map(line_range, fn(y) {
    line_range |> list.map(fn(x) {
      vectors |> list.map(fn (v) {
        is_word_at(lines, x, y, v.0, v.1, "XMAS")
      })
    }) |> list.flatten
  }) |> list.flatten |> list.fold(0, int.add)
}

fn read_x_wing_file_day4(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  let line_range = list.range(0, list.length(lines) - 1)
  line_range |> list.map(fn(y) {
    line_range |> list.map(fn(x) {
      are_words_at(lines, x, y, "MAS")
    })
  }) |> list.flatten |> list.fold(0, int.add)
}

pub fn main() {
  io.print("Day 4 (test): ")
  "./test4.txt" |> read_file_day4 |> int.to_string |> io.println
  io.print("Day 4 (input): ")
  "./day4.txt" |> read_file_day4 |> int.to_string |> io.println
  io.print("Day 4 p2 (test): ")
  "./test4.txt" |> read_x_wing_file_day4 |> int.to_string |> io.println
  io.print("Day 4 p2 (input): ")
  "./day4.txt" |> read_x_wing_file_day4 |> int.to_string |> io.println
}
