module monitoring.webserver.main;

import monitoring.webserver.websocket : WebSocketHandler;

import vibe.http.fileserver : HTTPFileServerSettings, serveStaticFiles;
import vibe.http.router : URLRouter;
import vibe.http.server : HTTPListener, HTTPServerSettings, listenHTTP;
import vibe.http.websockets : handleWebSockets, WebSocket;

@safe:

class WebServer
{
    private URLRouter m_router;
    private HTTPServerSettings m_httpServerSettings;
    private HTTPListener m_httpListener;

    this()
    {
	    m_router = new URLRouter;
        m_httpServerSettings = new HTTPServerSettings;

	    m_router.get(
            "/ws",
            handleWebSockets((scope WebSocket s) => new WebSocketHandler(s).run())
        );
        m_router.get(
            "/ontologies/*",
            serveStaticFiles("./static/ontologies/", new HTTPFileServerSettings("/ontologies"))
        );
        m_router.get(
            "/images/*",
            serveStaticFiles("./static/images/", new HTTPFileServerSettings("/images"))
        );

	    m_httpServerSettings.bindAddresses = ["::1", "127.0.0.1"];
	    m_httpServerSettings.port = 3001;
    }

    void start()
    in (m_httpListener == HTTPListener.init)
    {
        m_httpListener = listenHTTP(m_httpServerSettings, m_router);
    }
}