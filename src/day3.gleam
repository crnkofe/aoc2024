import gleam/string
import gleam/option
import util
import gleam/int
import gleam/list
import gleam/io
import gleam/regexp
import file_streams/file_stream as fs

fn join_strings(s1, s2) {
  string.concat([string.trim_end(s1), string.trim_end(s2)])
}

fn read_file_day1(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])
  list.fold(lines, "", join_strings)
}

fn read_file_corrected(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  let assert Ok(re_remove) = regexp.from_string("don't\\(\\).*?do\\(\\)")
  let assert Ok(re_remove_end) = regexp.from_string("don't\\(\\).*?$")

  let line = list.fold(lines, "", join_strings)
  let x1 = regexp.replace(re_remove, line, "")
  regexp.replace(re_remove_end, x1, "")
}

fn sum_mul(line) {
  let assert Ok(re) = regexp.from_string("mul\\(([0-9]{1,3}),([0-9]{1,3})\\)")
  let line_muls = list.map(regexp.scan(re, line), fn(match) {
    case list.length(match.submatches) == 2 {
      True -> {
        let assert Ok(l) = list.first(match.submatches)
        let assert Ok(r) = list.last(match.submatches)
        let sl = option.unwrap(l, "0")
        let sr = option.unwrap(r, "0")
        let assert Ok(il) = int.parse(sl)
        let assert Ok(ir) = int.parse(sr)
        il * ir
      }
      False -> 0
    }
  })
  list.fold(line_muls, 0, int.add)
}

pub fn main() {
  io.print("Day 3 (test): ")
  "./test3.txt" |> read_file_day1 |> sum_mul |> int.to_string |> io.println
  io.print("Day 3 (input): ")
  "./day3.txt" |> read_file_day1 |> sum_mul |> int.to_string |> io.println
  io.print("Day 3 p2 (test): ")
  "./test31.txt" |> read_file_corrected |> sum_mul |> int.to_string |> io.println
  io.print("Day 3 p2 (input): ")
  "./day3.txt" |> read_file_corrected |> sum_mul |> int.to_string |> io.println
}
