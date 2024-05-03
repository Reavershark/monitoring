/**
 * Functionality for parsing and traveling the resource graph.
 * Also contains the GraphNode interface.
 */
module monitoring.resource_graph.graph;

import vibe.data.json : Json;

import std.algorithm : map;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.string : capitalize;
import std.uni : isAlpha, isAlphaNum;
import std.sumtype : SumType, match;

import vibe.core.log;

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

interface GraphNode
{
    /** 
     * Calls the method referred to by `segment` and returns its result.
     * Params:
     *   segment = The last segment of a Query, with type = Method.
     * Returns: The result of the method referred to by `segment`.
     */
    SumType!(GraphNode, Json) query(in GraphPathSegment segment, bool isLastSegment);

    /** 
     * Every time the signal referred to by `segment` is triggered, calls hook with the value of that signal.
     * Calling this multiple times with the same hook will result in that hook also being called multiple times when the
     * signal triggers.
     * Params:
     *   segment = The last segment of a Query, with type = Signal.
     *   hook = A delegate referring to a class method with signature "void method(string)".
     */
    // void subscribe(in GraphPathSegment segment, void delegate(string) hook);

    /**
     * Removes a hook from the call list of the signal referred to by `segment`.
     * If a hook was added multiple times with multiple `subscribe` calls, all those subscriptions will be undone.
     * Params:
     *   segment = The last segment of a Query, with type = Signal.
     *   hook = A delegate referring to a class method with signature "void method(string)".
     */
    // void unsubscribe(in GraphPathSegment segment, void delegate(string) hook);

    /*
     * Serialize to json.
     */
    // Json toJson() const; // optional
}

//                 //
// Graph traveling //
//                 //

/** 
 * Travels the graph with a valid Request object.
 * Returns: A json string
 */
Json executeRequest(in Request req, GraphNode root) nothrow @trusted
in (root !is null)
{
    try
    {
        req.validate;

        enforce(req.path.length >= 1);

        GraphNode curr = root;
        foreach (i, segment; req.path)
        {
            bool isLastSegment = (i + 1 == req.path.length);

            if (!isLastSegment)
            {
                logDebug(f!"Current node: %s"(curr));
                curr = curr.query(segment, isLastSegment)
                    .match!(
                        (GraphNode n) => n,
                        _ => assert(false),
                );
                logDebug(f!"Current node: %s"(curr));
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
                    throw new Exception("subscribe not implemented"); //curr.subscribe(segment);
                case RequestType.Unsubscribe:
                    throw new Exception("unsubscribe not implemented"); //curr.unsubscribe(segment);
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

@("Test handleRequest accepting root node")
unittest
{
    import monitoring.resource_graph.mixins;

    final class RootNode : GraphNode
    {
        int[] graph_foo()
        {
            return [0, 1, 2];
        }

        mixin emptyResolveMixin;
        mixin queryMixin!graph_foo;

        void subscribe(GraphPathSegment segment, void delegate(string) hook)
        {
        }

        void unsubscribe(GraphPathSegment segment, void delegate(string) hook)
        {
        }
    }

    RootNode root = new RootNode;
    auto req = Request(RequestType.Query, [GraphPathSegment("foo")]);
    Json s = executeRequest(req, root);
    assert(s == Json([Json(0), Json(1), Json(2)]));
}
