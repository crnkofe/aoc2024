import gleam/io
import gleam/int
import gleam/list
import gleam/string
import util
import file_streams/file_stream as fs

fn is_safe_subreport(split_line, fn_compare, idx) {
  let safer_report = list.flatten([list.take(split_line, idx-1), list.drop(split_line, idx)])
  let line_pairs = list.window(safer_report, 2)
  let matches = list.filter(line_pairs, fn(x) {
    let assert Ok(first) = list.first(x)
    let assert Ok(last) = list.last(x)
    let assert Ok(x) = int.parse(first)
    let assert Ok(y) = int.parse(last)
    fn_compare(x, y)
  })
  list.length(matches) == list.length(line_pairs)
}

fn are_safe_reports(line, fn_compare) {
  let split_line = string.split(string.trim_end(line), " ")
  let safe_subreports = list.map(list.range(0, list.length(split_line)), fn (i) {
    is_safe_subreport(split_line, fn_compare, i)
  })
  list.any(safe_subreports, fn(x) { x })
}

fn is_safe_report(line, fn_compare) {
  let split_line = string.split(string.trim_end(line), " ")
  is_safe_subreport(split_line, fn_compare, -1)
}

fn filter_reports(filename, fn_is_safe) {
  let assert Ok(f) = fs.open_read(filename)
  let lines = util.read_loop(f, [])

  list.filter(lines, fn(line) {
    fn_is_safe(line, fn(x, y) {
      x < y && {y - x} >= 1 && {y-x} <= 3
    }) || fn_is_safe(line, fn(x, y) {
      x > y && {x - y} >= 1 && {x - y} <= 3
    })
  })
}

fn filter_valid_reports(filename) {
  filter_reports(filename, is_safe_report)
}

fn filter_valid_subreports(filename) {
  filter_reports(filename, are_safe_reports)
}

fn solve_day2(valid_reports) {
  "Day2: " <> int.to_string(list.length(valid_reports))
}

pub fn main() {
  "./test2.txt" |> filter_valid_reports |> solve_day2 |> io.println
  "./input2.txt" |> filter_valid_reports |> solve_day2 |> io.println
  "./test2.txt" |> filter_valid_subreports |> solve_day2 |> io.println
  "./input2.txt" |> filter_valid_subreports |> solve_day2 |> io.println
}