module monitoring.app;

import monitoring.webserver.main;

import std.stdio;

import pyd.pyd, pyd.embedded;

@safe:

shared static this() @trusted
{
    py_init;
}

void main()
{
    WebServer webServer = new WebServer;
    webServer.run;
}
