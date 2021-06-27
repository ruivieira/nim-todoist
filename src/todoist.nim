## Todoist REST API client

import httpclient
import json
import options

type Todoist = object
    token*: string
    client*: HttpClient

type DueDate* = object
    # Whether the task has a recurring due date
    recurring*: bool
    # Human defined date in arbitrary format
    `string`*: string
    # Date in format YYYY-MM-DD corrected to user's timezone
    date*: string

type TodoistTask* = object
    # Task ID
    id*: int
    # Task's project ID (read-only)
    project_id*: int
    # ID of section task belongs to
    section_id*: int
    # ID of parent task (read-only, absent for top-level tasks)
    parent_id*: Option[int]
    # Position under the same parent or project for top-level tasks (read-only)
    order*: int
    # Task content. This value may contain markdown-formatted text and hyperlinks
    content*: string
    # A description for the task. This value may contain markdown-formatted text and hyperlinks
    description*: string
    # Flag to mark completed tasks
    completed*: bool
    # Array of label IDs, associated with a task
    label_ids*: seq[int]
    # Task priority from 1 (normal, default value) to 4 (urgent)
    priority*: int
    # Number of task comments
    comment_count*: int
    created*: string
    # object representing task due date/time
    due*: Option[DueDate]

  type TodoistProject* = object
      id*: int  # Project ID
      order*: Option[int] # Project position under the same parent (read-only)
      color*: int # A numeric ID representing the color of the project icon
      name*: string # Project name
      comment_count*: int # Number of project comments
      `shared`*: bool # Whether the project is shared
      favorite*: bool # Whether the project is a favorite 
      sync_id*: int # Identifier to find the match between different copies of shared projects
      url*: string # URL to access this project in the Todoist web or mobile applications

type TodoistLabel* = object
    id*:int # Label ID
    name*:string # Label name
    color*:int # A numeric ID representing the color of the label icon
    order*: int # Number used by clients to sort list of labels
    favorite*: bool # Whether the label is a favorite

type TodoistSection* = object
    id*:int # Section id
    project_id*: int # ID of the project section belongs to
    order*: int # Section position among other sections from the same project
    name*: string # Section name

proc newTodoist*(token: string) : Todoist =
    return Todoist(token: token, client: newHttpClient())

proc buildGETRequest(todoist: Todoist, url: string) : Response =
    let headers = newHttpHeaders()
    headers["Authorization"] = "Bearer " & todoist.token
    let response = request(todoist.client, url, "GET", "", headers)
    return response

proc getAll[T](todoist: Todoist, url: string) : seq[T] =
    var results = newSeq[T]()
    let response = buildGETRequest(todoist, url)
    let json = parseJson(response.body)
    for item in json:
        results.add(to(item, T))
    return results    

proc getSingle[T](todoist: Todoist, url: string): T =
    let response = buildGETRequest(todoist, url)
    let json = parseJson(response.body)
    return to(json, T)

proc getActiveTasks*(todoist: Todoist) : seq[TodoistTask] =
    let url = "https://api.todoist.com/rest/v1/tasks"
    let tasks = getAll[TodoistTask](todoist, url)
    return tasks

proc getTask*(todoist: Todoist, id: int) : TodoistTask =
    let url = "https://api.todoist.com/rest/v1/tasks/" & $id
    return getSingle[TodoistTask](todoist, url)

proc getAllProjects*(todoist: Todoist): seq[TodoistProject] =
    let url = "https://api.todoist.com/rest/v1/projects"
    let projects = getAll[TodoistProject](todoist, url)
    return projects

proc getProject*(todoist: Todoist, id: int) : TodoistProject =
    let url = "https://api.todoist.com/rest/v1/projects/" & $id
    return getSingle[TodoistProject](todoist, url)

proc getAllLabels*(todoist: Todoist) : seq[TodoistLabel] =
    let url = "https://api.todoist.com/rest/v1/labels"
    let labels = getAll[TodoistLabel](todoist, url)
    return labels

proc getProjectSections*(todoist: Todoist, project_id: int) : seq[TodoistSection] =
    let url = "https://api.todoist.com/rest/v1/sections?project_id=" & $project_id
    let sections = getAll[TodoistSection](todoist, url)
    return sections