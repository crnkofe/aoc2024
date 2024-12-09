import gleam/io
import gleam/int
import gleam/list
import file_streams/file_stream as fs
import file_streams/file_stream_error as fse

type Point = #(Int, Int)

pub fn point_add(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

pub fn point_sub(p1: Point, p2: Point) -> Point {
  point_add(p1, point_neg(p2))
}

pub fn point_neg(p1: Point) -> Point {
  #(-p1.0, -p1.1)
}

pub fn read_loop(f, res) {
  case fs.read_line(f) {
    Ok(line) -> {
      read_loop(f, [line, ..res])
    }
    Error(fse.Eof) -> list.reverse(res)
    _ -> panic as "can't read file"
  }
}

pub fn assert_nth(lst, index) {
  let result = list.drop(lst, index)
  let assert Ok(first) = list.first(result)
  first
}

pub fn point_in_map(p: Point, map_size: Int) -> Bool {
  p.0 >= 0 && p.0 < map_size && p.1 >= 0 && p.1 < map_size
}

pub fn print_num(prefix: String, n: Int) {
  io.print(prefix)
  io.print(": ")
  n |> int.to_string |> io.println
}
