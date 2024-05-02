module monitoring.main;

import monitoring.parse_rdf : rdfDiscoverAll;
import monitoring.webserver.main : WebServer;

import std.stdio;

import vibe.core.log;

import pyd.pyd : py_init;

@safe:

void main() @trusted
{
    py_init;

    rdfDiscoverAll;

    WebServer webServer = new WebServer;
    webServer.run;
}
