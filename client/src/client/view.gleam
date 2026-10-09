import client/model.{
  type Filter, type Model, type Msg, Active, All, Completed, UserChoseFilter,
  UserDeletedTask, UserDismissedError, UserSubmittedDraft, UserToggledTask,
  UserTypedDraft,
}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import lustre/attribute.{class}
import lustre/element.{type Element, text}
import lustre/element/html
import lustre/event
import shared/task.{type Task}

pub fn view(model: Model) -> Element(Msg) {
  html.main(
    [class("min-h-dvh bg-gradient-to-b from-pink-50 to-white px-4 py-16")],
    [
      html.div([class("mx-auto max-w-lg")], [
        header(),
        form(model),
        error_banner(model),
        task_list(model),
        footer(model),
      ]),
    ],
  )
}

fn header() -> Element(Msg) {
  html.header([class("mb-8 text-center")], [
    html.h1([class("text-4xl font-bold tracking-tight text-zinc-900")], [
      text("Gleam "),
      html.span([class("text-pink-500")], [text("full-stack")]),
    ]),
    html.p([class("mt-2 text-zinc-500")], [
      text("Lustre on the client, Wisp on the server, one shared type."),
    ]),
  ])
}

fn form(model: Model) -> Element(Msg) {
  html.form(
    [class("flex gap-2"), event.on_submit(fn(_) { UserSubmittedDraft })],
    [
      html.input([
        class(
          "flex-1 rounded-lg border border-zinc-200 bg-white px-4 py-2.5 shadow-sm outline-none focus:border-pink-400 focus:ring-2 focus:ring-pink-100",
        ),
        attribute.placeholder("What needs doing?"),
        attribute.aria_label("New task"),
        attribute.value(model.draft),
        attribute.maxlength(task.max_title_length),
        event.on_input(UserTypedDraft),
      ]),
      html.button(
        [
          attribute.type_("submit"),
          class(
            "rounded-lg bg-pink-500 px-5 py-2.5 font-medium text-white shadow-sm transition hover:bg-pink-600",
          ),
        ],
        [text("Add")],
      ),
    ],
  )
}

fn error_banner(model: Model) -> Element(Msg) {
  case model.error {
    None -> element.none()
    Some(message) ->
      html.div(
        [
          attribute.role("alert"),
          class(
            "mt-4 flex items-center justify-between rounded-lg bg-red-50 px-4 py-2 text-sm text-red-700",
          ),
        ],
        [
          text(message),
          html.button(
            [
              event.on_click(UserDismissedError),
              attribute.aria_label("Dismiss"),
              class("font-bold"),
            ],
            [text("×")],
          ),
        ],
      )
  }
}

fn task_list(model: Model) -> Element(Msg) {
  case model.loading, model.visible_tasks(model) {
    True, _ -> empty_state("Loading…")
    False, [] -> empty_state("Nothing here yet.")
    False, tasks ->
      html.ul(
        [
          class(
            "mt-6 divide-y divide-zinc-100 rounded-lg border border-zinc-200 bg-white shadow-sm",
          ),
        ],
        list.map(tasks, task_item),
      )
  }
}

fn task_item(task: Task) -> Element(Msg) {
  html.li([class("group flex items-center gap-3 px-4 py-3")], [
    html.input([
      attribute.type_("checkbox"),
      attribute.checked(task.completed),
      attribute.aria_label("Mark " <> task.title <> " as done"),
      class("size-4 accent-pink-500"),
      event.on_check(UserToggledTask(task.id, _)),
    ]),
    html.span(
      [
        class("flex-1"),
        attribute.classes([#("text-zinc-400 line-through", task.completed)]),
      ],
      [text(task.title)],
    ),
    html.button(
      [
        event.on_click(UserDeletedTask(task.id)),
        attribute.aria_label("Delete " <> task.title),
        class(
          "text-zinc-300 opacity-0 transition group-hover:opacity-100 hover:text-red-500 focus:opacity-100",
        ),
      ],
      [text("×")],
    ),
  ])
}

fn empty_state(message: String) -> Element(Msg) {
  html.p([class("mt-6 py-10 text-center text-zinc-400")], [text(message)])
}

fn footer(model: Model) -> Element(Msg) {
  case model.tasks {
    [] -> element.none()
    _ ->
      html.footer(
        [class("mt-4 flex items-center justify-between text-sm text-zinc-500")],
        [
          html.span([], [
            text(int.to_string(model.remaining(model)) <> " left"),
          ]),
          html.div(
            [class("flex gap-1")],
            list.map([All, Active, Completed], filter_button(model.filter, _)),
          ),
        ],
      )
  }
}

fn filter_button(current: Filter, filter: Filter) -> Element(Msg) {
  let label = case filter {
    All -> "All"
    Active -> "Active"
    Completed -> "Completed"
  }
  html.button(
    [
      event.on_click(UserChoseFilter(filter)),
      class("rounded-md px-2 py-1 transition hover:text-zinc-900"),
      attribute.classes([
        #("bg-white font-medium text-zinc-900 shadow-sm", current == filter),
      ]),
    ],
    [text(label)],
  )
}
