module monitoring.main;

import monitoring.parse_rdf : rdfDiscoverAndWatchForChanges;
import monitoring.webserver.main : WebServer;

import std.stdio;

import vibe.core.core;
import vibe.core.log;

import pyd.pyd : py_init;

@safe:

/// Catches segfaults and prints debug info, only works on x86 and x86_64.
void setupSegfaultHandler() @trusted
{
    import etc.linux.memoryerror;

    static if (is(typeof(registerMemoryErrorHandler)))
        registerMemoryErrorHandler();
}

void main() @trusted
{
    setupSegfaultHandler;

    py_init;

    WebServer webServer = new WebServer;
    webServer.start;

    runTask(() => rdfDiscoverAndWatchForChanges);

    runEventLoop;
}
