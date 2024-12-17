import gleam/float
import gleam/io
import gleam/int
import gleam/dict
import gleam/string
import util
import gleam/list
import file_streams/file_stream as fs

type Registers = dict.Dict(Int, Int)
type Program = dict.Dict(Int, List(Int))

fn read_file_day17(filename) -> #(Registers, Program) {
  let assert Ok(f) = fs.open_read(filename)
  let raw_machine = util.read_loop(f, [])
  let registers = raw_machine
  |> list.take_while(fn (l) {
    !{l |> string.trim_end |> string.is_empty}
  }) |> list.index_map(fn (line, register_i) {
    let assert Ok(register_init) = line
      |> string.trim_end
      |> string.replace("Register A: ", "")
      |> string.replace("Register B: ", "")
      |> string.replace("Register C: ", "")
      |> int.parse
    #(register_i, register_init)
  }) |> dict.from_list

  let assert Ok(raw_program) = raw_machine
    |> list.drop_while(fn (l) {
      !{l |> string.trim_end |> string.is_empty}
    }) |> list.drop(1) |> list.first
  let opcodes = raw_program |> string.replace("Program: ", "") |> string.split(",") |> list.map(fn (x) {
    let assert Ok(res) = int.parse(x)
    res
  }) |> list.sized_chunk(2) |> list.index_map(fn (p, i) {
    #(i, p)
  }) |> dict.from_list
  #(registers, opcodes)
}

fn get(regs, i) {
  case dict.get(regs, i) {
    Ok(v) -> v
    _ -> 0
  }
}

fn combo(val, regs) {
  case val {
    0 -> 0
    1 -> 1
    2 -> 2
    3 -> 3
    4 -> get(regs, 0)
    5 -> get(regs, 1)
    6 -> get(regs, 2)
    _ -> val
  }
}

fn pow(x, n) -> Float {
  let assert Ok(res) = float.power(x, n)
  res
}

fn machine_state(pc, regs, opcodes) {
  case dict.get(opcodes, pc) {
    Ok(opcode) -> io.debug(list.flatten([[pc], opcode, dict.values(regs)]))
    _ -> io.debug([pc, ..dict.values(regs)])
  }
}

fn run_it(pc, opcodes, regs, out) {
//  machine_state(pc, regs, opcodes)
  case dict.get(opcodes, pc) {
    Ok(opcode) -> {
      case opcode {
        [0, n] -> {  // adv - division
          let result = get(regs, 0) / float.round(pow(2., int.to_float(combo(n, regs))))
          run_it(pc+1, opcodes, dict.insert(regs, 0, result), out)
        }
        [1, n] -> {  // bxl - bitwise xor
          let result = int.bitwise_exclusive_or(get(regs, 1), n)
          run_it(pc+1, opcodes, dict.insert(regs, 1, result), out)
        }
        [2, n] -> {  // bst - modulo 8
          let result = combo(n, regs) % 8
          run_it(pc+1, opcodes, dict.insert(regs, 1, result), out)
        }
        [3, n] -> {  // jnz
          case get(regs, 0) {
            0 -> run_it(pc+1, opcodes, regs, out)
            _ -> {
              run_it(combo(n, regs), opcodes, regs, out)
            }
          }
        }
        [4, _] -> {  // bxc
          let result = int.bitwise_exclusive_or(get(regs, 1), get(regs, 2))
          run_it(pc+1, opcodes, dict.insert(regs, 1, result), out)
        }
        [5, n] -> {  // out
          let result = int.to_string(combo(n, regs) % 8)
          case out {
            "" -> run_it(pc+1, opcodes, regs, result)
            _ ->  run_it(pc+1, opcodes, regs, string.concat([out, ",", result]))
          }

        }
        [6, n] -> {  // adv + output in B
          let result = get(regs, 0) / float.round(pow(2., int.to_float(combo(n, regs))))
          run_it(pc+1, opcodes, dict.insert(regs, 1, result), out)
        }
        [7, n] -> {  // adv + output in C
          let result = get(regs, 0) / float.round(pow(2., int.to_float(combo(n, regs))))
          run_it(pc+1, opcodes, dict.insert(regs, 2, result), out)
        }
        _ -> out
      }
    }
    _ -> out
  }
}

fn reverse_engineer(n, regs, codes, out) -> Int {
  // looking at my opcodes everytime the program restarts
  // the value in register A is then < A_prev / 8 - x
  // to get the program to output itself find the first
  // value that computes any valid postfix


  let res = run_it(0, codes, dict.insert(regs, 0, n), "")
  case res == out {
    True -> n
    False -> {
      case string.ends_with(out, res) {
        True -> reverse_engineer(n * 8, regs, codes, out)
        False -> reverse_engineer(n + 1, regs, codes, out)
      }
    }
  }
}

pub fn main() {
  let #(test_regs, test_codes) = "test17.txt" |> read_file_day17
  let test_postfix = list.range(0, {test_codes |> dict.keys |> list.length} - 1)
  |> list.map(fn(x) {
    let assert Ok(res) = dict.get(test_codes, x)
    res |> list.map(int.to_string)
  }) |> list.flatten |> string.join(",")

  let #(regs, codes) = "day17.txt" |> read_file_day17
  let postfix = list.range(0, {codes |> dict.keys |> list.length} - 1)
    |> list.map(fn(x) {
      let assert Ok(res) = dict.get(codes, x)
      res |> list.map(int.to_string)
  }) |> list.flatten |> string.join(",")

  io.print("Day 17 (test): ")
  io.println(run_it(0, test_codes, test_regs, ""))
  util.print_num("Day 17 p2(test)", reverse_engineer(1, test_regs, test_codes, test_postfix))

  io.print("Day 17 (input): ")
  io.println(run_it(0, codes, regs, ""))
  util.print_num("Day 17 p2 (input)", reverse_engineer(1, regs, codes, postfix))
}
