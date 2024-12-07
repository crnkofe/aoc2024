import gleam/set
import gleam/dict
import gleam/string
import util
import gleam/int
import gleam/list
import gleam/io
import file_streams/file_stream as fs

fn point_in_map(p: #(Int, Int), map_size: Int) -> Bool {
  p.0 >= 0 && p.0 < map_size && p.1 >= 0 && p.1 < map_size
}

fn rotate(v: #(Int, Int)) -> #(Int, Int) {
  let rotations = [#(0, -1), #(1, 0), #(0, 1), #(-1, 0)]
  let remainder = rotations |> list.drop_while(fn(r) {
    r != v
  }) |> list.drop(1)
  case remainder {
    [h, ..] -> { h }
    [] -> {
      let assert Ok(first) = list.first(rotations)
      first
    }
  }
}

fn traverse(map: dict.Dict(#(Int, Int), String), map_size: Int, p: #(Int, Int), dir: #(Int, Int)) ->  List(#(Int, Int)) {
  case point_in_map(p, map_size) {
    False -> []
    True -> {
      let next_p = #(p.0 + dir.0, p.1 + dir.1)
      case dict.get(map, next_p) {
        Ok("#") -> {
          traverse(map, map_size, p, rotate(dir))
        }
        _ -> list.flatten([[p], traverse(map, map_size, next_p, dir)])
      }
    }
  }
}

fn is_loop(map: dict.Dict(#(Int, Int), String), map_size: Int, p: #(Int, Int), dir: #(Int, Int), visited: set.Set(#(#(Int, Int), #(Int, Int)))) -> Bool {
//  io.debug(p)
//  io.debug(dir)
  case point_in_map(p, map_size) {
    False -> False
    True -> {
      case set.contains(visited, #(p, dir)) {
        True -> {
//          io.debug("Loop")
//          io.debug(p)
//          io.debug(dir)
          True
        }
        False -> {
          let next_p = #(p.0 + dir.0, p.1 + dir.1)
          case dict.get(map, next_p) {
            Ok("#") -> {
              is_loop(map, map_size, p, rotate(dir), visited)
            }
            _ -> is_loop(map, map_size, next_p, dir, set.insert(visited, #(p, dir)))
          }
        }
      }
    }
  }
}

fn generate_valid_obstructed_maps(map: dict.Dict(#(Int, Int), String), traversed_path: List(#(Int, Int))) -> List(dict.Dict(#(Int, Int), String)) {
  traversed_path |> list.unique |> list.map(fn(p) {
     dict.insert(map, p, "#")
  })
}

fn read_file_day6(filename) -> dict.Dict(#(Int, Int), String) {
  let assert Ok(f) = fs.open_read(filename)
  util.read_loop(f, []) |> list.index_map(fn(line, y) {
    string.to_graphemes(line) |> list.index_map(fn(c, x) {
       case c == "#" || c == "^" {
         True -> #(#(x, y), c)
         False -> #(#(-1, -1), "")
       }
    }) |> list.filter(fn (p) { p.1 != ""})
  }) |> list.flatten |> dict.from_list
}

fn starting_point(map: dict.Dict(#(Int, Int), String)) {
  let assert Ok(starting_point) = map |> dict.filter(fn (_k, v) {
    v == "^"
  }) |> dict.to_list |> list.first
  starting_point.0
}

pub fn main() {
  let map_test = "./test6.txt" |> read_file_day6
  let start_test = map_test |> starting_point
  io.print("Day 6 (test): ")
  let start_path_test = traverse(map_test,  10, start_test, #(0, -1))
  start_path_test |> list.unique |> list.length |> int.to_string |> io.println

  io.print("Day 6 p2 (test): ")
  let generated_invalid_maps_test = generate_valid_obstructed_maps(map_test, list.drop(start_path_test, 1))
  generated_invalid_maps_test |> list.filter(fn(obstructed_map) {
    is_loop(obstructed_map, 10, start_test, #(0, -1), set.from_list([]))
  }) |> list.length |> int.to_string |> io.println

  let map = "./day6.txt" |> read_file_day6
  let start = map |> starting_point
  let start_path = traverse(map, 130, start,#(0, -1))
  io.print("Day 6: ")
  start_path |> list.unique |> list.length |> int.to_string |> io.println

  io.print("Day 6 p2 (input): ")
  let generated_invalid_maps_test = generate_valid_obstructed_maps(map, list.drop(start_path, 1))
  generated_invalid_maps_test |> list.filter(fn(obstructed_map) {
    is_loop(obstructed_map, 130, start, #(0, -1), set.from_list([]))
  }) |> list.length |> int.to_string |> io.println
}
