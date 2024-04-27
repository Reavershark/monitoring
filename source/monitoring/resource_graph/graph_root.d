module monitoring.resource_graph.graph_root;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : queryMixin;
import monitoring.script : ScriptManager;

import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.string : capitalize;

import vibe.data.json : Json, serializeToJson;

@safe:

final class GraphRoot : GraphNode
{
    private static typeof(this) sm_instance;

    private ScriptManager m_scriptManager;

    private this()
    {
        m_scriptManager = new ScriptManager;
    }

    static synchronized typeof(this) getInstance()
    {
        if (sm_instance is null)
            sm_instance = new typeof(this);
        return sm_instance;
    }

    string test(in string s) const
    {
        return f!"Echo %s!"(s);
    }

    ScriptManager scriptManager() pure => m_scriptManager;

    mixin queryMixin!(
        test, scriptManager,
    );
}
