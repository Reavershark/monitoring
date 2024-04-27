module monitoring.webserver.websocket;

import monitoring.resource_graph.graph : executeRequest, parseRequest, Request;
import monitoring.resource_graph.graph_root : GraphRoot;

import vibe.core.log;
import vibe.data.json : Json, parseJson, JSONException;
import vibe.http.websockets : WebSocket, WebSocketException;

import std.exception : enforce;
import std.format : f = format;
import std.stdio : writeln, writefln;

@safe:

class WebSocketHandler
{
    private WebSocket m_ws;

    this(WebSocket ws)
    in (ws !is null)
    {
        m_ws = ws;
        logInfo("Got new web socket connection.");
    }

    void run()
    {
        while (m_ws.connected)
        {
            try
            {
                Json msg = readMessage;
                try
                    handleMessage(msg);
                catch (Exception e)
                    logWarn(f!"Exception during handleMessage: %s"(e.msg));
            }
            catch (Exception e)
                logWarn(f!"Exception during readMessage: %s"(e.msg));
        }
    }

    Json readMessage()
    {
        string text = m_ws.receiveText;

        try
            return parseJson(text);
        catch (JSONException e)
            throw new WebSocketException(f!"Message is not in json format: %s"(text));
    }

    private void handleMessage(Json msg)
    {
        Request req = parseRequest(msg);
        writefln!"Parsed msg: %s"(req);

        Json result = executeRequest(req, GraphRoot.getInstance);
        writefln!"Result: %s"(result);
        m_ws.send(result.toString);
    }
}
