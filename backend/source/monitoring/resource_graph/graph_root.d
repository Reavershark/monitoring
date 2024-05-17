module monitoring.resource_graph.graph_root;

import monitoring.dashboard : DashboardManager;
import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : graphNodeMixin;
import monitoring.script : ScriptManager;
import monitoring.util.meta : Pack;

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
    private DashboardManager m_dashboardManager;

    private this()
    {
        m_scriptManager = new ScriptManager;
        m_dashboardManager = new DashboardManager;
    }

    static synchronized GraphRoot getInstance()
    {
        if (sm_instance is null)
            sm_instance = new typeof(this);
        return sm_instance;
    }

    ScriptManager scriptManager() pure => m_scriptManager;
    DashboardManager dashboardManager() pure => m_dashboardManager;

    mixin graphNodeMixin!(
        Pack!(scriptManager, dashboardManager),
    );
}
