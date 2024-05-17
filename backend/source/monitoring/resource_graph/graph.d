/**
 * Functionality for parsing and traveling the resource graph.
 * Also contains the GraphNode interface.
 */
module monitoring.resource_graph.graph;

import monitoring.util.meta : Pack;

import std.algorithm : map;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.string : capitalize;
import std.sumtype : match, SumType;
import std.uni : isAlpha, isAlphaNum;

import vibe.core.log;
import vibe.data.json : Json;

@safe:

struct Request
{
    RequestType type;
    GraphPathSegment[] path;

    void validate() const
    {
        // TODO
    }
}

enum RequestType
{
    Query,
    Subscribe,
    Unsubscribe,
}

struct GraphPathSegment
{
    /// Method or signal name
    string name;
    /// Method arguments (empty if name refers to a signal)
    Json[] args;
}

Request parseRequest(in Json jsonReq)
{
    // TODO: validate

    // dfmt off
    Request req;
    req.type = jsonReq["type"].get!string.capitalize.to!RequestType;
    req.path = jsonReq["path"]
        .get!(Json[])
        .map!((jsonSegment) => GraphPathSegment(
            name: jsonSegment["name"].get!string,
            args: ("args" in jsonSegment) ? jsonSegment["args"].get!(Json[]).array.dup : [],
        ))
        .array;
    // dfmt on

    return req;
}

interface GraphSubscriber
{
    /// False result indicates failiure, might want to unsubscribe/discard of delegate.
    bool sendEvent(in string event, in Json eventData);
}

interface GraphNode
{
    /** 
     * Calls the method referred to by `segment` and returns its result.
     * Params:
     *   segment = The last segment of a Query, with type = Method.
     * Returns: The result of the method referred to by `segment`.
     */
    SumType!(GraphNode, Json) query(in GraphPathSegment segment, in bool lastSegment);

    void subscribe(GraphSubscriber subscriber, string event);

    void unsubscribe(GraphSubscriber subscriber, string event);
}


private enum bool implementsGraphNodeImpl(T : GraphNode) = true;
enum bool implementsGraphNode(T) = __traits(compiles, implementsGraphNodeImpl!T);

//                 //
// Graph traveling //
//                 //

/** 
 * Travels the graph with a valid Request object.
 * Returns: A json string
 */
Json executeRequest(in Request req, GraphNode graphRoot, GraphSubscriber graphSubscriber) nothrow @trusted
in (graphRoot !is null)
in (graphSubscriber !is null)
{
    try
    {
        req.validate;

        enforce(req.path.length >= 1);

        GraphNode curr = graphRoot;
        foreach (i, segment; req.path)
        {
            bool isLastSegment = (i + 1 == req.path.length);

            if (!isLastSegment)
            {
                curr = curr.query(segment, isLastSegment).match!(
                    (GraphNode n) => n,
                    _ => assert(false),
                );
                enforce(curr !is null);
            }
            else
            {
                final switch (req.type)
                {
                case RequestType.Query:
                    return curr.query(segment, isLastSegment).match!(
                        (Json j) => j,
                        _ => assert(false),
                    );
                case RequestType.Subscribe:
                    curr.subscribe(graphSubscriber, segment.name);
                    return Json(null);
                case RequestType.Unsubscribe:
                    curr.unsubscribe(graphSubscriber, segment.name);
                    return Json(null);
                }
            }
        }
    }
    catch (Exception e)
    {
        try
            return Json(["error": Json(e.msg)]);
        catch (Exception e)
            return Json(e.msg);
    }
    assert(false);
}

@("Test executeRequest accepting root node")
unittest
{
    import monitoring.resource_graph.mixins : graphNodeMixin;

    final class RootNode : GraphNode
    {
        int[] foo() => [0, 1, 2];

        mixin graphNodeMixin!foo;
    }

    RootNode root = new RootNode;
    auto req = Request(RequestType.Query, [GraphPathSegment("foo")]);
    Json s = executeRequest(req, root, null);
    assert(s == Json([Json(0), Json(1), Json(2)]));
}
