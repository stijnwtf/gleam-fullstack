import client/model.{
  Active, ApiCreatedTask, ApiDeletedTask, ApiReturnedTasks, ApiUpdatedTask,
  Completed, Model, UserChoseFilter, UserSubmittedDraft, UserTypedDraft,
}
import gleam/option.{None, Some}
import gleeunit
import shared/task.{Task}

pub fn main() -> Nil {
  gleeunit.main()
}

// The update function is pure, so client logic is tested without a browser.

fn loaded() -> model.Model {
  let #(m, _) =
    model.update(
      model.init(),
      ApiReturnedTasks(
        Ok([
          Task(id: 1, title: "Write code", completed: True),
          Task(id: 2, title: "Ship it", completed: False),
        ]),
      ),
    )
  m
}

pub fn loading_tasks_test() {
  let m = loaded()
  assert !m.loading
  assert model.remaining(m) == 1
}

pub fn empty_draft_shows_error_test() {
  let #(m, _) = model.update(model.init(), UserSubmittedDraft)
  let assert Some(_) = m.error
}

pub fn submitting_clears_draft_immediately_test() {
  let #(m, _) = model.update(loaded(), UserTypedDraft("Celebrate"))
  let #(m, _) = model.update(m, UserSubmittedDraft)
  assert m.draft == ""
  assert m.error == None
}

pub fn created_task_is_appended_test() {
  let new = Task(id: 3, title: "Celebrate", completed: False)
  let #(m, _) = model.update(loaded(), ApiCreatedTask(Ok(new)))
  assert model.remaining(m) == 2
}

pub fn updated_and_deleted_tasks_test() {
  let done = Task(id: 2, title: "Ship it", completed: True)
  let #(m, _) = model.update(loaded(), ApiUpdatedTask(Ok(done)))
  assert model.remaining(m) == 0

  let #(m, _) = model.update(m, ApiDeletedTask(1, Ok(Nil)))
  assert m.tasks == [done]
}

pub fn filters_test() {
  let #(m, _) = model.update(loaded(), UserChoseFilter(Active))
  let assert [Task(id: 2, ..)] = model.visible_tasks(m)

  let #(m, _) = model.update(m, UserChoseFilter(Completed))
  let assert [Task(id: 1, ..)] = model.visible_tasks(m)

  let assert Model(filter: Completed, ..) = m
}
