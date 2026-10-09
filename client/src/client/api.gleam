//// Typed HTTP calls to the server. Requests and responses use the codecs in
//// `shared/task`, so a mismatch with the server is a compile error.

import gleam/int
import gleam/json
import lustre/effect.{type Effect}
import rsvp
import shared/task.{type Task}

pub fn list_tasks(
  to_msg: fn(Result(List(Task), rsvp.Error(String))) -> msg,
) -> Effect(msg) {
  rsvp.get("/api/tasks", rsvp.expect_json(task.list_decoder(), to_msg))
}

pub fn create_task(
  title: String,
  to_msg: fn(Result(Task, rsvp.Error(String))) -> msg,
) -> Effect(msg) {
  rsvp.post(
    "/api/tasks",
    task.create_to_json(task.CreateTask(title:)),
    rsvp.expect_json(task.decoder(), to_msg),
  )
}

pub fn set_completed(
  id: Int,
  completed: Bool,
  to_msg: fn(Result(Task, rsvp.Error(String))) -> msg,
) -> Effect(msg) {
  rsvp.patch(
    "/api/tasks/" <> int.to_string(id),
    task.update_to_json(task.UpdateTask(completed:)),
    rsvp.expect_json(task.decoder(), to_msg),
  )
}

pub fn delete_task(
  id: Int,
  to_msg: fn(Result(Nil, rsvp.Error(String))) -> msg,
) -> Effect(msg) {
  rsvp.delete(
    "/api/tasks/" <> int.to_string(id),
    json.null(),
    rsvp.expect_ok_response(fn(result) {
      case result {
        Ok(_) -> to_msg(Ok(Nil))
        Error(error) -> to_msg(Error(error))
      }
    }),
  )
}
