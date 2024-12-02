import gleam/io
import gleam/int
import gleam/list
import gleam/string
import file_streams/file_stream as fs
import util

fn read_file(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  let split_pairs = list.map(lines, fn(x) {
    let assert Ok(fmt_pair) = string.split_once(x, "   ")
    let assert Ok(parsed1) = int.parse(fmt_pair.0)
    let assert Ok(parsed2) = int.parse(string.trim_end(fmt_pair.1))
    #(parsed1, parsed2)
  })
  #(list.map(split_pairs, fn(x) { x.0 }), list.map(split_pairs, fn(x) { x.1 }))
}

fn solve_day1(split_lists: #(List(Int), List(Int))) {
  let diffs = list.map(list.zip(list.sort(split_lists.0, int.compare), list.sort(split_lists.1, int.compare)), fn(tup) {
    int.absolute_value(tup.1 - tup.0)
  })
  let result = list.fold(diffs, 0, int.add)
  "Day1: " <> int.to_string(result)
}

fn solve_day2(split_lists: #(List(Int), List(Int))) {
  let result = list.map(split_lists.0, fn(x) {
     x * list.length(list.filter(split_lists.1, fn (rx) { x == rx }))
  })
  "Day2: " <> int.to_string(list.fold(result, 0, int.add))
}

pub fn main() {
  "./test1.txt" |> read_file |> solve_day1 |> io.println
  "./day1.txt" |> read_file |> solve_day1 |> io.println
  "./test1.txt" |> read_file |> solve_day2 |> io.println
  "./day1.txt" |> read_file |> solve_day2 |> io.println
}
