// Opens the things:/// URL given on stdin without bringing Things to the front.
// stdin rather than argv keeps the auth token out of the process table.
ObjC.import("AppKit");

function run() {
	const data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
	const raw = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js.trim();
	if (!raw.startsWith("things:///")) {
		throw new Error("refusing to open a non-things URL");
	}
	const url = $.NSURL.URLWithString(raw);
	if (url.isNil()) {
		throw new Error("malformed things URL");
	}

	const config = $.NSWorkspaceOpenConfiguration.configuration;
	config.activates = false;

	let done = false;
	let failure = null;
	$.NSWorkspace.sharedWorkspace.openURLConfigurationCompletionHandler(url, config, (app, err) => {
		if (!err.isNil()) {
			failure = err.localizedDescription.js;
		}
		done = true;
	});

	const deadline = $.NSDate.dateWithTimeIntervalSinceNow(5);
	while (!done && $.NSDate.date.compare(deadline) < 0) {
		$.NSRunLoop.currentRunLoop.runUntilDate($.NSDate.dateWithTimeIntervalSinceNow(0.02));
	}
	if (failure) {
		throw new Error(failure);
	}
	if (!done) {
		throw new Error("timed out opening things URL");
	}
	return "ok";
}
