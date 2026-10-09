import gleam/http
import gleam/int
import gleam/json
import gleeunit
import server/router
import server/store
import server/web.{Context}
import shared/task.{Task}
import wisp/simulate

pub fn main() -> Nil {
  gleeunit.main()
}

fn context() -> web.Context {
  let assert Ok(store) = store.start()
  Context(store:, static_directory: "priv/static")
}

pub fn health_test() {
  let response =
    simulate.request(http.Get, "/api/health")
    |> router.handle_request(context())

  assert response.status == 200
  assert simulate.read_body(response) == "ok"
}

pub fn create_and_list_tasks_test() {
  let ctx = context()

  let response =
    simulate.request(http.Post, "/api/tasks")
    |> simulate.json_body(
      task.create_to_json(task.CreateTask("  Learn Gleam ")),
    )
    |> router.handle_request(ctx)

  assert response.status == 201
  let assert Ok(created) =
    json.parse(simulate.read_body(response), task.decoder())
  assert created == Task(id: 1, title: "Learn Gleam", completed: False)

  let response =
    simulate.request(http.Get, "/api/tasks")
    |> router.handle_request(ctx)

  let assert Ok(tasks) =
    json.parse(simulate.read_body(response), task.list_decoder())
  assert tasks == [created]
}

pub fn create_rejects_empty_title_test() {
  let response =
    simulate.request(http.Post, "/api/tasks")
    |> simulate.json_body(task.create_to_json(task.CreateTask("   ")))
    |> router.handle_request(context())

  assert response.status == 422
}

pub fn update_and_delete_task_test() {
  let ctx = context()
  let created = store.create(ctx.store, "Ship it")

  let response =
    simulate.request(http.Patch, "/api/tasks/" <> int.to_string(created.id))
    |> simulate.json_body(task.update_to_json(task.UpdateTask(completed: True)))
    |> router.handle_request(ctx)

  assert response.status == 200
  let assert Ok(updated) =
    json.parse(simulate.read_body(response), task.decoder())
  assert updated.completed

  let response =
    simulate.request(http.Delete, "/api/tasks/" <> int.to_string(created.id))
    |> router.handle_request(ctx)

  assert response.status == 204
  assert store.all(ctx.store) == []
}

pub fn unknown_task_is_404_test() {
  let response =
    simulate.request(http.Delete, "/api/tasks/999")
    |> router.handle_request(context())

  assert response.status == 404
}

pub fn unknown_api_route_is_404_test() {
  let response =
    simulate.request(http.Get, "/api/nope")
    |> router.handle_request(context())

  assert response.status == 404
}
