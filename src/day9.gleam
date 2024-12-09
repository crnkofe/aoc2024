import gleam/order
import gleam/string
import util
import gleam/int
import gleam/list
import file_streams/file_stream as fs

fn checksum(at: Int, len: Int, multiplier: Int) -> Int {
  case len <= 0 {
    True -> 0
    False -> {
      list.range(at, at + len - 1) |> list.fold(0, fn(sum, i) {
        sum + i * multiplier
      })
    }
  }
}

fn compact(lst: List(List(Int)), lst_i : Int, el_i : Int, lst_reverse: List(List(Int)), lst_reverse_i: Int) {
  case lst_i >= lst_reverse_i {
    True -> {
      case lst_reverse {
        [[back_block_count, _], .._rest_last] -> checksum(el_i, back_block_count, lst_reverse_i)
        _ -> 0
      }
    }
    False -> {
      let current_checksum = case lst {
        [[block_count, empty_space], ..rest] -> {
          let sum = checksum(el_i, block_count, lst_i)
          let el_free_i = el_i + block_count
          case empty_space == 0 {
            True -> sum + compact(rest, lst_i + 1, el_i + block_count, lst_reverse, lst_reverse_i)
            _ -> {
              sum + case lst_reverse {
                [[back_block_count, .._back_free_rest], ..back_rest] -> {
                  case int.compare(empty_space, back_block_count) {
                    order.Lt -> {
                      let empty_checksum = checksum(el_free_i, empty_space, lst_reverse_i)
                      empty_checksum + compact(rest, lst_i + 1, el_free_i + empty_space, [[back_block_count-empty_space, 0],..back_rest], lst_reverse_i)
                    }
                    order.Eq -> {
                      let empty_checksum = checksum(el_free_i, back_block_count, lst_reverse_i)
                      empty_checksum + compact(rest, lst_i + 1, el_free_i + back_block_count, back_rest, lst_reverse_i - 1)
                    }
                    order.Gt -> {
                      let empty_checksum = checksum(el_free_i, back_block_count, lst_reverse_i)
                      empty_checksum + compact([[0, empty_space - back_block_count], ..rest], lst_i, el_free_i + back_block_count, back_rest, lst_reverse_i - 1)
                    }
                  }
                }
                _ -> 0
              }
            }
          }
        }
        _ -> 0
      }
      current_checksum
    }
  }
}

fn defrag_contiguous(lst_reverse: List(List(Int))) {
  case lst_reverse {
    [[idx, size, ..free], ..rest] -> {
      let original_list = rest |> list.reverse
      let #(before_blocks, after_blocks) = original_list |> list.split_while(fn (el) {
        case el {
          [_idx, _size_cur, free_cur] -> free_cur < size
          _ -> False
        }
      })
      case list.is_empty(after_blocks) {
        True -> list.flatten([[[idx, size, ..free]], defrag_contiguous(before_blocks |> list.reverse)])
        False -> {
          case after_blocks {
            [[after_block_idx, after_block_size, after_block_free], ..after_blocks_rest] -> {
              let merged = list.flatten([
                before_blocks,
                [[after_block_idx, after_block_size, 0], [idx, size, after_block_free - size]],
                after_blocks_rest
              ]) |> list.reverse
              list.flatten([[[idx, 0, size + {free |> list.fold(0, int.add)}]], merged |> defrag_contiguous])
            }
            _ -> {
              []
            }
          }
        }
      }
    }
    _ -> []
  }
}

fn checksum_contiguous(lst: List(List(Int)), el_i: Int) {
  case lst {
    [[idx, size, ..free], ..rest] -> {
      checksum(el_i, size, idx)  + checksum_contiguous(rest, el_i + size + list.fold(free, 0, int.add))
    }
    _ -> 0
  }
}

fn read_file_day9(filename) -> Int {
  let assert Ok(f) = fs.open_read(filename)
  let assert Ok(input) = util.read_loop(f, []) |> list.first
  let paired_input = input |> string.trim_end |> string.to_graphemes |> list.map(fn (s: String) {
    let assert Ok(i) = int.parse(s)
    i
  }) |> list.sized_chunk(2)
  compact(paired_input, 0, 0, list.reverse(paired_input), list.length(paired_input) - 1)
}

fn read_file_day9_contigous(filename) {
  let assert Ok(f) = fs.open_read(filename)
  let assert Ok(input) = util.read_loop(f, []) |> list.first
  let paired_input = input |> string.trim_end |> string.to_graphemes |> list.map(fn (s: String) {
    let assert Ok(i) = int.parse(s)
    i
  }) |> list.sized_chunk(2) |> list.index_map(fn (x, i) {
    [i, ..x]
  })

  let result = defrag_contiguous(paired_input |> list.reverse)
  result |> list.reverse |> checksum_contiguous(0)
}

pub fn main() {
  util.print_num("Day 9 (test)", "./test9.txt" |> read_file_day9)
  util.print_num("Day 9 (input)", "./day9.txt" |> read_file_day9)
  util.print_num("Day 9 p2 (test)", "./test9.txt" |> read_file_day9_contigous)
  util.print_num("Day 9 p2 (input)", "./day9.txt" |> read_file_day9_contigous)
}

