/**
 * Mixins for easily implementing the GraphNode interface in a class.
 */
module monitoring.resource_graph.mixins;

import monitoring.util.meta : Pack;

import std.traits : isInstanceOf;

@safe:

/** 
 * When mixed into a class, this template provides a `query` method as in the GraphNode interface.
 * Params:
 *   MethodsPack: Pack of final methods of the current class that return a string (usually json).
 */
template graphNodeMixin(alias MethodsPack, string[] events = [])
        if (isInstanceOf!(Pack, MethodsPack))
{
    import monitoring.resource_graph.graph : GraphNode, GraphPathSegment, GraphSubscriber, implementsGraphNode;

    import std.algorithm : canFind, map, startsWith;
    import std.conv : to;
    import std.exception : enforce;
    import std.format : f = format;
    import std.meta : staticMap;
    import std.range : iota, join;
    import std.sumtype : SumType;
    import std.traits : arity, isFinalFunction, Parameters, ReturnType, Unqual;

    import vibe.data.json : deserializeJson, Json, serializeToJson, serializeToJsonString;

    static assert(implementsGraphNode!(typeof(this)), "mixin not in a class body");
    static foreach (Method; MethodsPack.Unpack)
        static assert(isFinalFunction!Method, f!`Not a final method: "%s"`(Method.stringof));
    static foreach (event; events)
        static assert(event.length, f!`Invalid event: "%s"`(event));

    private bool[GraphSubscriber][string] m_subscribersPerEvent;

    SumType!(GraphNode, Json) query(in GraphPathSegment segment, in bool lastSegment)
    {
        switch (segment.name)
        {
            // Each case converts the segment.args to the types expected by the method segment.name.
            // Then it calls the method with name segment.name with those arguments and returns the result.
            static foreach (Method; MethodsPack.Unpack)
            {
        case __traits(identifier, Method): // case MethodName
                // This extra scope is just so we can reuse local variable names
                {
                    enum string MethodName = __traits(identifier, Method);
                    alias MethodArgCount = arity!Method;
                    alias MethodArgTypes = Parameters!Method;
                    alias MethodReturnType = ReturnType!Method;

                    enforce(
                        segment.args.length == MethodArgCount,
                        f!"Method %s expected %d arguments instead of %d"(
                            MethodName, MethodArgCount, segment.args.length)
                    );

                    // Convert each argument to the type expected by the method
                    static foreach (i, Type; staticMap!(Unqual, MethodArgTypes))
                    {
                        mixin(f!"Type arg_%d;"(i)); // Declare first so we can use try/catch
                        try
                            mixin(f!"arg_%d = segment.args[i].deserializeJson!Type;"(i));
                        catch (Exception e)
                            throw new Exception(f!"Failed to convert string \"%s\" to type %s: %s"(
                                    segment.args[i], Type.stringof, e.message));
                    }

                    // Generate argument list string ("arg_0, arg_1, ...")
                    enum string argsToMixin = iota(MethodArgCount)
                            .map!(i => f!"arg_%d"(i))
                            .join(", ");

                    // Finally, generate the method call
                    MethodReturnType methodResult = mixin(f!"%s(%s)"(MethodName, argsToMixin));

                    static if (implementsGraphNode!(ReturnType!Method))
                        if (!lastSegment)
                            return typeof(return)(cast(GraphNode) methodResult);
                    static if (is(ReturnType!Method == void))
                        return typeof(return)(serializeToJson(null));
                    else
                        return typeof(return)(serializeToJson(methodResult));
                }
            }

        default:
            throw new Exception(f!"Invalid method name %s"(segment.name));
        }
    }

    void subscribe(GraphSubscriber subscriber, string event)
    {
        enforce(events.canFind(event), "Invalid event");

        bool[GraphSubscriber] subscribers = m_subscribersPerEvent.require(event);
        enforce(subscriber !in subscribers, "Already subscribed");
        subscribers[subscriber] = true;
    }

    void unsubscribe(GraphSubscriber subscriber, string event)
    {
        enforce(events.canFind(event), "Invalid event");

        bool[GraphSubscriber] subscribers = m_subscribersPerEvent.require(event);
        enforce(subscriber in subscribers, "Not subscribed");
        subscribers.remove(subscriber);
    }

    private void raise(string event)(in Json eventData) if (events.canFind(event))
    {
        bool[GraphSubscriber] subscribers = m_subscribersPerEvent.require(event);
        GraphSubscriber[] failed;
        foreach (subscriber; subscribers.byKey)
            subscriber.sendEvent(event, eventData);
        foreach (subscriber; failed)
            subscribers.remove(subscriber);
    }
}

@("Test graphNodeMixin")
unittest
{
    import vibe.data.json : Json;

    bool success = false;

    final class A
    {
        GraphNode foo(int a, string b)
        {
            assert(a == 1 && b == "str");
            success = true;
            return null;
        }

        mixin graphNodeMixin!foo;
    }

    A a = new A;

    GraphPathSegment segment;
    segment.name = "foo";
    segment.args = [Json(1), Json("str")];

    assert(a.query(segment) is null);
    assert(success);
}
