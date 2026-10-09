import client/api
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import rsvp
import shared/task.{type Task}

pub type Filter {
  All
  Active
  Completed
}

pub type Model {
  Model(
    tasks: List(Task),
    draft: String,
    filter: Filter,
    loading: Bool,
    error: Option(String),
  )
}

pub type Msg {
  UserTypedDraft(String)
  UserSubmittedDraft
  UserToggledTask(id: Int, completed: Bool)
  UserDeletedTask(id: Int)
  UserChoseFilter(Filter)
  UserDismissedError
  ApiReturnedTasks(Result(List(Task), rsvp.Error(String)))
  ApiCreatedTask(Result(Task, rsvp.Error(String)))
  ApiUpdatedTask(Result(Task, rsvp.Error(String)))
  ApiDeletedTask(id: Int, result: Result(Nil, rsvp.Error(String)))
}

pub fn init() -> Model {
  Model(tasks: [], draft: "", filter: All, loading: True, error: None)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserTypedDraft(draft) -> #(Model(..model, draft:), effect.none())

    UserSubmittedDraft ->
      case task.validate_title(model.draft) {
        // Clear right away so typing the next task can't race the response.
        Ok(title) -> #(
          Model(..model, draft: "", error: None),
          api.create_task(title, ApiCreatedTask),
        )
        Error(message) -> #(Model(..model, error: Some(message)), effect.none())
      }

    UserToggledTask(id:, completed:) -> #(
      model,
      api.set_completed(id, completed, ApiUpdatedTask),
    )

    UserDeletedTask(id:) -> #(model, api.delete_task(id, ApiDeletedTask(id, _)))

    UserChoseFilter(filter) -> #(Model(..model, filter:), effect.none())

    UserDismissedError -> #(Model(..model, error: None), effect.none())

    ApiReturnedTasks(Ok(tasks)) -> #(
      Model(..model, tasks:, loading: False),
      effect.none(),
    )

    ApiCreatedTask(Ok(created)) -> #(
      Model(..model, tasks: list.append(model.tasks, [created])),
      effect.none(),
    )

    ApiUpdatedTask(Ok(updated)) -> #(
      Model(
        ..model,
        tasks: list.map(model.tasks, fn(t) {
          case t.id == updated.id {
            True -> updated
            False -> t
          }
        }),
      ),
      effect.none(),
    )

    ApiDeletedTask(id:, result: Ok(Nil)) -> #(
      Model(..model, tasks: list.filter(model.tasks, fn(t) { t.id != id })),
      effect.none(),
    )

    ApiReturnedTasks(Error(_))
    | ApiCreatedTask(Error(_))
    | ApiUpdatedTask(Error(_))
    | ApiDeletedTask(result: Error(_), ..) -> #(
      Model(
        ..model,
        loading: False,
        error: Some("Couldn't reach the server. Is it running?"),
      ),
      effect.none(),
    )
  }
}

pub fn visible_tasks(model: Model) -> List(Task) {
  case model.filter {
    All -> model.tasks
    Active -> list.filter(model.tasks, fn(t) { !t.completed })
    Completed -> list.filter(model.tasks, fn(t) { t.completed })
  }
}

pub fn remaining(model: Model) -> Int {
  list.count(model.tasks, fn(t) { !t.completed })
}
