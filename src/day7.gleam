import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

fn calc(target: Int, result: Int, numbers: List(Int)) -> Bool {
  case result > target && list.is_empty(numbers) {
    True -> False // can never go back to real result afterwards
    False -> {
      case result == target && list.is_empty(numbers) {
        True -> True
        False -> {
          case numbers {
            [next_num, ..rest] -> calc(target, result + next_num, rest) || calc(target, result * next_num, rest)
            [] -> False
          }
        }
      }
    }
  }
}

fn valid_eq(l: #(Int, List(Int))) -> Bool {
  case l.1 {
    [first, ..rest] -> calc(l.0, first, rest)
    [] -> False
  }
}

fn merge_num(a: Int, b: Int) -> Int {
  case a == 0 || b == 0 {
    True -> a + b
    False -> {
      let assert Ok(r) = int.parse(string.concat([int.to_string(a), int.to_string(b)]))
      case int.to_string(r) == string.concat([int.to_string(a), int.to_string(b)]) {
        False -> io.debug("False")
        True -> ""
      }
      r
    }
  }
}

fn calc_with_or(target: Int, result: Int, numbers: List(Int)) -> Bool {
  case result == target && list.is_empty(numbers) {
    True -> True
    False -> {
      case numbers {
        [next_num, ..rest] -> {
          calc_with_or(target, result + next_num, rest) ||
          calc_with_or(target, result * next_num, rest) ||
          calc_with_or(target, merge_num(result, next_num), rest)
        }
        [] -> False
      }
    }
  }
}

fn valid_eq_with_or(l: #(Int, List(Int))) -> Bool {
  case l.1 {
    [first, ..rest] -> {
      calc_with_or(l.0, first, rest)
    }
    [] -> False
  }
}

fn read_file_day7(filename) -> List(#(Int, List(Int))) {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.map(fn(line) {
    string.split(string.trim_end(line), ": ")
  }) |> list.map(fn(d) {
     case d {
       [result_raw, rest] -> {
         let assert Ok(result) = int.parse(result_raw)
         #(result, string.split(rest, " ") |> list.map(fn(r) {
           let assert Ok(res) = int.parse(r)
           res
         }))
       }
       _ -> #(0, [])
     }
  })
}

pub fn main() {
  io.print("Day 7 (test): ")
  "./test7.txt" |> read_file_day7 |> list.filter(fn(eq) {
    valid_eq(eq)
  }) |> list.fold(0, fn(result: Int, eq: #(Int, List(Int))) { result + eq.0 } ) |> int.to_string |> io.println

  io.print("Day 7 (input): ")
  "./day7.txt" |> read_file_day7 |> list.filter(fn(eq) {
    valid_eq(eq)
  }) |> list.fold(0, fn(result: Int, eq: #(Int, List(Int))) { result + eq.0 } ) |> int.to_string |> io.println

  io.print("Day 7 p2 (test): ")
  "./test7.txt" |> read_file_day7 |> list.filter(fn(eq) {
    valid_eq_with_or(eq)
  }) |> list.fold(0, fn(result: Int, eq: #(Int, List(Int))) { result + eq.0 } ) |> int.to_string |> io.println

  io.print("Day 7 p2 (input): ")
  "./day7.txt" |> read_file_day7 |> list.filter(fn(eq) {
    valid_eq_with_or(eq)
  }) |> list.fold(0, fn(result: Int, eq: #(Int, List(Int))) { result + eq.0 } ) |> int.to_string |> io.println
}
