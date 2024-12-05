import gleam/list
import file_streams/file_stream as fs
import file_streams/file_stream_error as fse

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