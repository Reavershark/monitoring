module monitoring.webserver.websocket;

import monitoring.resource_graph.graph : executeRequest, GraphSubscriber, parseRequest, Request;
import monitoring.resource_graph.graph_root : GraphRoot;

import vibe.core.log;
import vibe.data.json : Json, parseJson, JSONException;
import vibe.http.websockets : WebSocket, WebSocketException;

import std.exception : enforce;
import std.format : f = format;
import std.stdio : writeln, writefln;

@safe:

class WebSocketHandler : GraphSubscriber
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
            Json msg = Json.emptyObject;
            Json response = Json.emptyObject;

            try
                msg = readMessage;
            catch (Exception e)
            {
                logWarn(f!"Exception during readMessage: %s"(e.msg));
                response["error"] = Json(e.msg);
            }

            if (msg != Json.emptyObject)
            {
                try
                    response["result"] = handleMessage(msg);
                catch (Exception e)
                {
                    logWarn(f!"Exception during handleMessage: %s"(e.msg));
                    response["error"] = Json(e.msg);
                }

                if ("requester" in msg)
                    response["requester"] = msg["requester"];
            }

            m_ws.send(response.toString);
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

    private Json handleMessage(Json msg)
    {
        Request req = parseRequest(msg);
        writefln!"Parsed msg: %s"(req);

        Json result = executeRequest(req, GraphRoot.getInstance, this);
        writefln!"Result: %s"(result);

        return result;
    }

    bool sendEvent(in string event, in Json eventData)
    {
        if (!m_ws.connected)
            return false;

        Json toSend = Json([
            "event": Json(event),
            "eventData": eventData,
        ]);

        try
            m_ws.send(toSend.toString);
        catch (Exception e)
            return false;

        return true;
    }
}
