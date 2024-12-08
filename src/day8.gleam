import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

type Map = dict.Dict(String, List(util.Point))

fn generate_antinodes(map_size: Int, p1: util.Point, v: util.Point, limit: Int) -> List(util.Point) {
  case limit == 0 || !util.point_in_map(p1, map_size) {
    True -> []
    False -> {
        let new_point = util.point_add(p1, v)
        case util.point_in_map(new_point, map_size) {
          True -> list.flatten([[new_point], generate_antinodes(map_size, new_point, v, limit - 1)])
          False -> generate_antinodes(map_size, new_point, v, limit - 1)
        }
    }
  }
}

fn comp_antinodes(map: Map, size: Int, limit: Int) {
  map |> dict.values |> list.map(fn (v) {
    v |> list.combination_pairs |> list.map(fn (pair) -> List(util.Point) {
      let #(p1, p2) = pair
      let v = util.point_sub(p1, p2)
      list.flatten([
        generate_antinodes(size, p1, v, limit),
        generate_antinodes(size, p2, util.point_neg(v), limit),
        [p1, p2]
      ])
    }) |> list.flatten
  }) |> list.flatten |> list.unique |> list.sort(fn (x, y) {
    case x.0 == y.0 {
      True -> int.compare(x.1, y.1)
      False -> int.compare(x.0, y.0)
    }
  })
}

fn read_file_day8(filename) -> Map {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.index_map(fn (line, y) {
    line |> string.trim_end |> string.to_graphemes |> list.index_map(fn (c, x) {
      #(c, #(x, y))
    }) |> list.filter(fn (kv) {
      kv.0 != "."
    })
  }) |> list.flatten |> list.group(fn (kv) {
    kv.0
  }) |> dict.map_values(fn (_k, v) {
     v |> list.map(fn (cxy) {
       cxy.1
     })
  })
}

fn map_size(filename) -> Int {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.length
}

pub fn main() {
  let test_map_size = "./test8.txt" |> map_size
  let input_map_size = "./day8.txt" |> map_size

  io.print("Day 8 (test): ")
  "./test8.txt" |> read_file_day8 |> comp_antinodes(test_map_size, 1) |> list.length |> int.to_string |> io.println

  io.print("Day 8 (input): ")
  "./day8.txt" |> read_file_day8 |> comp_antinodes(input_map_size, 1) |> list.length |> int.to_string |> io.println

  io.print("Day 8 p2 (test): ")
  "./test8.txt" |> read_file_day8 |> comp_antinodes(test_map_size, 100000) |> list.length |> int.to_string |> io.println

  io.print("Day 8 (input): ")
  "./day8.txt" |> read_file_day8 |> comp_antinodes(input_map_size, 1000000) |> list.length |> int.to_string |> io.println
}
