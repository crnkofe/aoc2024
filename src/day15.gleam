import gleam/io
import gleam/int
import gleam/dict
import gleam/string
import util
import gleam/list
import file_streams/file_stream as fs

type Map = dict.Dict(util.Point, String)

fn print_map(map, at) {
  let keys = map |> dict.keys
  let ys = keys |> list.map(fn (key: util.Point) {
    key.1
  }) |> list.unique |> list.sort(int.compare)
  let xs = keys |> list.map(fn (key: util.Point) {
    key.0
  }) |> list.unique |> list.sort(int.compare)
  ys |> list.map(fn (y) {
    let line = xs |> list.map(fn (x) {
      case at == #(x, y) {
        True -> "@"
        _ -> {
          case dict.get(map, #(x, y)) {
            Ok(v) -> v
            _ -> "?"
          }
        }
      }
    }) |> string.join("")
    io.println(line)
  })
}

fn map_score(map: Map, c) -> Int {
  map |> dict.filter(fn (k, v) {
    v == c
  }) |> dict.keys |> list.fold(0, fn(acc, p) {
    acc + 100 * p.1 + p.0
  })
}

fn push_one_block(map, at, next) -> Map {
  let assert Ok(v) = dict.get(map, at)
  map
  |> dict.delete(at)
  |> dict.insert(next, v)
  |> dict.insert(at, "." )
}

fn is_free_floor(map, p) -> Bool {
  case dict.get(map, p) {
    Ok(".") -> True
    _ -> False
  }
}

fn push_stack(map: Map, at: util.Point, dir: util.Point) -> Map {
  let next_bloc = util.point_add(at, dir)
  case dir.1 {
    0 -> {
      case dict.get(map, next_bloc) {
        Ok("O") | Ok("[") | Ok("]") -> {
          let new_map = push_stack(map, next_bloc, dir)
          case dict.get(new_map, next_bloc) {
            Ok(".") -> push_one_block(new_map, at, next_bloc)
            _ -> map  // failed to move stack
          }
        }
        Ok(".") -> push_one_block(map, at, next_bloc)
        _ -> map
      }
    }
    _ -> {
      case dict.get(map, next_bloc) {
        Ok("O") -> {
          let new_map = push_stack(map, next_bloc, dir)
          case dict.get(new_map, next_bloc) {
            Ok(".") -> push_one_block(new_map, at, next_bloc)
            _ -> map  // failed to move stack
          }
        }
        Ok("[") -> {
          let new_map = push_stack(map, next_bloc, dir)
          let other_side = util.point_add(next_bloc, #(1, 0))
          let new_map_other = push_stack(new_map, other_side, dir)
          case is_free_floor(new_map_other, next_bloc) && is_free_floor(new_map_other, other_side) {
            True -> push_one_block(new_map_other, at, next_bloc)
            _ -> map
          }
        }
        Ok("]") -> {
          let new_map = push_stack(map, next_bloc, dir)
          let other_side = util.point_add(next_bloc, #(-1, 0))
          let new_map_other = push_stack(new_map, other_side, dir)
          case is_free_floor(new_map_other, next_bloc) && is_free_floor(new_map_other, other_side) {
            True -> push_one_block(new_map_other, at, next_bloc)
            _ -> map
          }
        }
        Ok(".") -> push_one_block(map, at, next_bloc)
        _ -> map
      }
    }
  }
}

fn push_box(map: Map, at, dir: util.Point) -> #(Map, util.Point) {
  let target_loc = util.point_add(at, dir)
  case dict.get(map, target_loc) {
    Ok(floor) -> {
      case floor {
        "." -> {
          #(map, target_loc)
        }
        "O" -> {
          let new_map = push_stack(map, target_loc, dir)
          case dict.get(new_map, target_loc) {
            Ok(".") -> #(new_map, target_loc)
            _ -> #(map, at)
          }
        }
        "[" -> {
          let new_map = push_stack(map, target_loc, dir)
          case dir.1 {
            0 -> {
              case dict.get(new_map, target_loc) {
                Ok(".") -> #(new_map, target_loc)
                _ -> #(map, at)
              }
            }
            _ -> {
              let other_side = util.point_add(target_loc, #(1, 0))
              let new_map_other = push_stack(new_map, other_side, dir)
              case is_free_floor(new_map_other, target_loc) && is_free_floor(new_map_other, other_side) {
                True -> #(new_map_other, target_loc)
                _ -> #(map, at)
              }
            }
          }
        }
        "]" -> {
          let new_map = push_stack(map, target_loc, dir)
          case dir.1 {
            0 -> {
              case dict.get(new_map, target_loc) {
                Ok(".") -> #(new_map, target_loc)
                _ -> {
                  #(map, at)
                }
              }
            }
            _ -> {
              let other_side = util.point_add(target_loc, #(-1, 0))
              let new_map_other = push_stack(new_map, other_side, dir)
              case is_free_floor(new_map_other, target_loc) && is_free_floor(new_map_other, other_side) {
                True -> #(new_map_other, target_loc)
                _ -> #(map, at)
              }
            }
          }
        }
        "#" -> #(map, at)  // hit the wall
        _ -> #(map, at)  // should never happen
      }
    }
    _ -> {
      #(map, at)  // nothing happens and this should never happen
    }
  }
}

fn read_file_day15(filename) -> #(Map, List(util.Point), util.Point) {
  let assert Ok(f) = fs.open_read(filename)
  let raw_map = util.read_loop(f, [])
  let map_with_start = raw_map
    |> list.take_while(fn (l) {
      !{l |> string.trim_end |> string.is_empty}
    }) |> list.index_map(fn (line, y) {
      line |> string.trim_end |> string.to_graphemes |> list.index_map(fn (c, x) {
        #(#(x, y), c)
      })
    }) |> list.flatten |> dict.from_list

  let assert Ok(start_point) = map_with_start
    |> dict.filter(fn (_k, v) {
      v == "@"
    })
    |> dict.keys
    |> list.first

  let map = map_with_start |> dict.filter(fn (_k, v) {
    v != "@"
  }) |> dict.insert(start_point, ".")

  let path = raw_map |> list.drop_while(fn (l) {
    !{l |> string.trim_end |> string.is_empty}
  }) |> list.drop(1) |> string.join("") |> string.to_graphemes
  |> list.map(fn(s) {
    case s {
      "<" -> #(-1, 0)
      "v" -> #(0, 1)
      ">" -> #(1, 0)
      "^" -> #(0, -1)
      _ -> #(0, 0)
    }
  })

  #(map, path, start_point)
}

pub fn simulate_part1(filename) -> Int {
  let #(map, path, start) = filename |> read_file_day15
  let #(final_map, finish) = path |> list.fold(#(map, start), fn (acc, dir) {
    let #(map, at) = acc
    let #(new_map, new_loc) = push_box(map, at, dir)
    #(new_map, new_loc)
  })
  map_score(final_map, "O")
}

pub fn simulate_part2(filename) -> Int {
  let #(original_map, path, original_start) = filename |> read_file_day15
  let map = original_map |> dict.to_list |> list.map(fn (kv) {
    let #(k, v) = kv
    let n1 = #(k.0 * 2, k.1)
    let n2 = util.point_add(n1, #(1, 0))
    case v {
      "#" -> [#(n1, "#"), #(n2, "#")]
      "O" -> [#(n1, "["), #(n2, "]")]
      "." ->  [#(n1, "."), #(n2, ".")]
      _ -> [#(n1, "?"), #(n2, "?")]
    }
  }) |> list.flatten |> dict.from_list
  let start = #(original_start.0 * 2, original_start.1)
  let #(final_map, _finish) = path |> list.fold(#(map, start), fn (acc, dir) {
    let #(map, at) = acc
    let #(new_map, new_loc) = push_box(map, at, dir)
    #(new_map, new_loc)
  })
//  io.println("Result")
//  print_map(final_map, finish)
  map_score(final_map, "[")
}

pub fn main() {
  util.print_num("Day 15 (test)", "./test15.txt" |> simulate_part1)
  util.print_num("Day 15 (input)", "./day15.txt" |> simulate_part1)
  util.print_num("Day 15 (test)", "./test15.txt" |> simulate_part2)
  util.print_num("Day 15 (input)", "./day15.txt" |> simulate_part2)
}
