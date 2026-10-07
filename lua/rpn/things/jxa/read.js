// Read-only queries against the Things 3 scripting dictionary; prints JSON.
// Every property is fetched in bulk (`toDos.name()`), never per item: one Apple
// Event per property instead of one per item is the difference between ~1s and minutes.
//
//   list <sourceId>      todos of a built-in list
//   logbook <limit>      most recently completed todos
//   project|area <id>    todos of a project or area
//   tag <name>           todos carrying a tag
//   open                 every open todo across the built-in lists
//   projects | areas | tags

const LISTS = ["TMInboxListSource", "TMTodayListSource", "TMNextListSource", "TMCalendarListSource", "TMSomedayListSource"];

function pad(n) {
	return String(n).padStart(2, "0");
}

// Local calendar date, so callers never deal with UTC offsets.
function ymd(d) {
	return d ? `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}` : null;
}

// Areas (and Today) list projects among their to-dos; writes must tell them apart.
function todos(app, spec) {
	const ids = spec.id();
	if (ids.length === 0) {
		return [];
	}
	const projectIds = new Set(app.projects.id());
	const name = spec.name();
	const status = spec.status();
	const notes = spec.notes();
	const tags = spec.tagNames();
	const due = spec.dueDate();
	const activation = spec.activationDate();
	const completion = spec.completionDate();
	const projectId = spec.project.id();
	const projectName = spec.project.name();
	const areaId = spec.area.id();
	const areaName = spec.area.name();
	return ids.map((id, i) => ({
		id,
		kind: projectIds.has(id) ? "project" : "todo",
		name: name[i],
		status: status[i],
		notes: notes[i],
		tags: tags[i],
		deadline: ymd(due[i]),
		when: ymd(activation[i]),
		completed: ymd(completion[i]),
		projectId: projectId[i],
		project: projectName[i],
		areaId: areaId[i],
		area: areaName[i],
	}));
}

function logbook(app, limit) {
	const spec = app.lists.byId("TMLogbookListSource").toDos;
	const n = Math.max(0, Math.min(limit, 500));
	const ids = spec.id().slice(0, n);
	const name = spec.name().slice(0, n);
	const status = spec.status().slice(0, n);
	const completion = spec.completionDate().slice(0, n);
	const projectName = spec.project.name().slice(0, n);
	return ids.map((id, i) => ({
		id,
		name: name[i],
		status: status[i],
		completed: ymd(completion[i]),
		project: projectName[i],
	}));
}

function openTodos(app) {
	const seen = new Set();
	const out = [];
	for (const list of LISTS) {
		for (const todo of todos(app, app.lists.byId(list).toDos)) {
			if (!seen.has(todo.id) && todo.status === "open") {
				seen.add(todo.id);
				out.push(todo);
			}
		}
	}
	return out;
}

function projects(app) {
	const spec = app.projects;
	const ids = spec.id();
	const name = spec.name();
	const status = spec.status();
	const area = spec.area.name();
	return ids
		.map((id, i) => ({ id, name: name[i], status: status[i], area: area[i] }))
		.filter((p) => p.status === "open");
}

function run(argv) {
	const app = Application("Things3");
	const [cmd, arg] = argv;
	let result;
	switch (cmd) {
		case "list":
			if (!LISTS.includes(arg)) {
				throw new Error(`unknown list: ${arg}`);
			}
			result = todos(app, app.lists.byId(arg).toDos);
			break;
		case "logbook":
			result = logbook(app, parseInt(arg, 10) || 50);
			break;
		case "project":
			result = todos(app, app.projects.byId(arg).toDos);
			break;
		case "area":
			result = todos(app, app.areas.byId(arg).toDos);
			break;
		case "tag":
			result = todos(app, app.tags.byName(arg).toDos);
			break;
		case "open":
			result = openTodos(app);
			break;
		case "projects":
			result = projects(app);
			break;
		case "areas": {
			const names = app.areas.name();
			result = app.areas.id().map((id, i) => ({ id, name: names[i] }));
			break;
		}
		case "tags":
			result = app.tags.name();
			break;
		default:
			throw new Error(`unknown command: ${cmd}`);
	}
	return JSON.stringify(result);
}
