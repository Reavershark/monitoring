module monitoring.resource_graph.graph_root;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : queryMixin;
import monitoring.scripts : Script, ScriptType;

import std.conv : to;
import std.exception : enforce;
import std.format : f = format;
import std.string : capitalize;

import vibe.data.json : Json, serializeToJson;

@safe:

final class GraphRoot : GraphNode
{
    private static typeof(this) sm_instance;

    private this()
    {
    }

    static synchronized typeof(this) getInstance()
    {
        if (sm_instance is null)
            sm_instance = new typeof(this);
        return sm_instance;
    }

    private Script[string] m_scripts;

    string test(in string s) const
    {
        return f!"Echo %s!"(s);
    }

    string[] listScripts() const
    {
        return m_scripts.keys;
    }

    string createScript(string type, string source)
    {
        auto script = new Script(type.capitalize.to!ScriptType, source);
        m_scripts[script.uuid] = script;
        return script.uuid;
    }

    Script getScript(string uuid)
    {
        enforce(uuid in m_scripts);
        return m_scripts[uuid];
    }

    bool removeScript(string uuid)
    {
        enforce(uuid in m_scripts);
        m_scripts.remove(uuid);
        return true;
    }

    mixin queryMixin!(
        test,
        listScripts, getScript, createScript, removeScript,
    );
}
