/**
 * Mixins for easily implementing the GraphNode interface in a class.
 */
module monitoring.resource_graph.mixins;

import monitoring.resource_graph.graph;

@safe:

/** 
 * When mixed into a class, this template provides a `query` method as in the GraphNode interface.
 * Params:
 *   Methods: List of final methods of the current class that return a string (usually json).
 */
template queryMixin(Methods...) if (Methods.length > 0)
{
    import monitoring.resource_graph.graph : GraphNode, GraphPathSegment;

    import std.algorithm : map, startsWith;
    import std.conv : to;
    import std.exception : enforce;
    import std.format : f = format;
    import std.meta : staticMap;
    import std.range : iota, join;
    import std.sumtype : SumType;
    import std.traits : arity, isFinalFunction, Parameters, ReturnType, Unqual;

    import vibe.data.json : deserializeJson, Json, serializeToJson, serializeToJsonString;

    SumType!(GraphNode, Json) query(in GraphPathSegment segment, bool lastSegment)
    {
        enum bool implementsGraphNodeImpl(T : GraphNode) = true;
        enum bool implementsGraphNode(T) = __traits(compiles, implementsGraphNodeImpl!T);

        static foreach (Method; Methods)
        {
            {
                static assert(isFinalFunction!Method);
                enum returnsGraphNode = implementsGraphNode!(ReturnType!Method);
                enum returnsJsonSerializable = __traits(compiles, {
                        ReturnType!Method a;
                        Json b = a.serializeToJson;
                    }) || is(ReturnType!Method == void);
                static assert(returnsGraphNode || returnsJsonSerializable);
            }
        }

        switch (segment.name)
        {
            // Each case converts the segment.args to the types expected by the method segment.name.
            // Then it calls the method with name segment.name with those arguments and returns the result.
            static foreach (Method; Methods)
            {
        case __traits(identifier, Method): // case MethodName
                // This extra scope is just so we can reuse local variable names
                {
                    const string MethodName = __traits(identifier, Method);
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
                    const string argsToMixin = iota(MethodArgCount)
                        .map!(i => f!"arg_%d"(i))
                        .join(", ");

                    enum callCode = f!"%s(%s)"(MethodName, argsToMixin);

                    // dfmt off
                    enum returnGraphNodeCode = f!"return typeof(return)(cast(GraphNode) %s);"(callCode);
                    enum returnVoidCode = f!"%s; return typeof(return)(serializeToJson(null));"(callCode);
                    enum returnJsonCode = f!"return typeof(return)(serializeToJson(%s));"(callCode);
                    // dfmt on

                    // Finally, generate the method call
                    static if (implementsGraphNode!(ReturnType!Method))
                    {
                        if (!lastSegment)
                        {
                            mixin(returnGraphNodeCode);
                        }
                        else
                        {
                            static if (is(ReturnType!Method == void))
                                mixin(returnVoidCode);
                            else
                                mixin(returnJsonCode);
                        }
                    }
                    else
                    {
                        static if (is(ReturnType!Method == void))
                            mixin(returnVoidCode);
                        else
                            mixin(returnJsonCode);
                    }
                }
            }

        default:
            throw new Exception(f!"Invalid method name %s"(segment.name));
        }
    }
}

template emptyQueryMixin()
{
    import monitoring.resource_graph.graph : GraphNode, GraphPathSegment;

    import std.sumtype : SumType;

    import vibe.data.json : Json;

    SumType!(GraphNode, Json) query(in GraphPathSegment _, bool isLastSegment)
    {
        assert(false, "This GraphNode has no query methods");
    }
}

@("Test queryMixin")
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

        mixin resolveMixin!foo;
    }

    A a = new A;

    GraphPathSegment segment;
    segment.name = "foo";
    segment.args = [Json(1), Json("str")];

    assert(a.query(segment) is null);
    assert(success);
}
