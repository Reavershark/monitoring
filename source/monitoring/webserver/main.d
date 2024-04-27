module monitoring.webserver.main;

import monitoring.webserver.websocket;

import vibe.core.core;
import vibe.core.log;
import vibe.http.fileserver : serveStaticFiles;
import vibe.http.router : URLRouter;
import vibe.http.server;
import vibe.http.websockets : WebSocket, handleWebSockets;

@safe:

class WebServer
{
    private URLRouter m_router;
    private HTTPServerSettings m_httpServerSettings;

    this()
    {
	    m_router = new URLRouter;
        m_httpServerSettings = new HTTPServerSettings;

	    m_router.get("/ws", handleWebSockets((scope WebSocket s) => new WebSocketHandler(s).run()));

	    m_httpServerSettings.bindAddresses = ["::1", "127.0.0.1"];
	    m_httpServerSettings.port = 3001;
    }

    void run()
    {
	    auto listener = listenHTTP(m_httpServerSettings, m_router);
	    runEventLoop;
    }
}