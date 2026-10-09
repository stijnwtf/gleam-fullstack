//// An in-memory task store, implemented as an OTP actor so concurrent
//// requests are serialised safely. Swap this module for a database
//// (e.g. `pog` for Postgres or `sqlight` for SQLite) when you need persistence.

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor
import shared/task.{type Task, Task}

pub opaque type State {
  State(tasks: Dict(Int, Task), next_id: Int)
}

pub type Message {
  All(reply: Subject(List(Task)))
  Create(title: String, reply: Subject(Task))
  SetCompleted(id: Int, completed: Bool, reply: Subject(Result(Task, Nil)))
  Delete(id: Int, reply: Subject(Result(Nil, Nil)))
}

const timeout = 1000

pub fn start() -> Result(Subject(Message), actor.StartError) {
  actor.new(State(tasks: dict.new(), next_id: 1))
  |> actor.on_message(handle_message)
  |> actor.start
  |> result_data
}

fn result_data(
  started: Result(actor.Started(Subject(Message)), actor.StartError),
) -> Result(Subject(Message), actor.StartError) {
  case started {
    Ok(actor.Started(data:, ..)) -> Ok(data)
    Error(error) -> Error(error)
  }
}

// API -------------------------------------------------------------------------

pub fn all(store: Subject(Message)) -> List(Task) {
  process.call(store, timeout, All)
}

pub fn create(store: Subject(Message), title: String) -> Task {
  process.call(store, timeout, Create(title, _))
}

pub fn set_completed(
  store: Subject(Message),
  id: Int,
  completed: Bool,
) -> Result(Task, Nil) {
  process.call(store, timeout, SetCompleted(id, completed, _))
}

pub fn delete(store: Subject(Message), id: Int) -> Result(Nil, Nil) {
  process.call(store, timeout, Delete(id, _))
}

// ACTOR -----------------------------------------------------------------------

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    All(reply:) -> {
      state.tasks
      |> dict.values
      |> list.sort(fn(a, b) { int.compare(a.id, b.id) })
      |> process.send(reply, _)
      actor.continue(state)
    }

    Create(title:, reply:) -> {
      let task = Task(id: state.next_id, title:, completed: False)
      process.send(reply, task)
      actor.continue(State(
        tasks: dict.insert(state.tasks, task.id, task),
        next_id: state.next_id + 1,
      ))
    }

    SetCompleted(id:, completed:, reply:) ->
      case dict.get(state.tasks, id) {
        Ok(task) -> {
          let task = Task(..task, completed:)
          process.send(reply, Ok(task))
          actor.continue(
            State(..state, tasks: dict.insert(state.tasks, id, task)),
          )
        }
        Error(Nil) -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }

    Delete(id:, reply:) ->
      case dict.has_key(state.tasks, id) {
        True -> {
          process.send(reply, Ok(Nil))
          actor.continue(State(..state, tasks: dict.delete(state.tasks, id)))
        }
        False -> {
          process.send(reply, Error(Nil))
          actor.continue(state)
        }
      }
  }
}
