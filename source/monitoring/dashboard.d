module monitoring.dashboard;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : queryMixin;

import std.uuid : randomUUID;

@safe:

final class Dashboard : GraphNode
{
    private string m_uuid;
    private string m_definition;

    this(string definition)
    {
        m_uuid = randomUUID.toString;
        m_definition = definition;
    }

    string uuid() const pure => m_uuid;
    string definition() const pure => m_definition;

    bool setDefinition(string definition) pure
    {
        m_definition = definition;
        return true;
    }

    mixin queryMixin!(
        uuid, definition, setDefinition,
    );
}

final class DashboardManager
{
    private Dashboard[string] m_dashboards;

    this()
    {
    }

    string[] listDashboards() const
    {
        return m_dashboards.keys;
    }

    string createDashboard(string definition)
    {
        Dashboard dashboard = new Dashboard(definition);
        m_dashboards[dashboard.uuid] = dashboard;
        return dashboard.uuid;
    }

    Dashboard getDashboard(string uuid)
    {
        enforce(uuid in m_dashboards);
        return m_dashboards[uuid];
    }

    bool removeDashboard(string uuid)
    {
        enforce(uuid in m_dashboards);
        m_dashboards.remove(uuid);
        return true;
    }

    mixin queryMixin!(
        listDashboards, getDashboard, createDashboard, removeDashboard,
    );
}
