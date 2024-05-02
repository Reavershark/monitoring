module monitoring.dashboard;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.mixins : queryMixin;

import std.exception : enforce;

import vibe.data.json : Json;

@safe:

final class Dashboard : GraphNode
{
    private string m_uri;
    private string m_definition;

    this(string uri, string definition)
    {
        m_uri = uri;
        m_definition = definition;
    }

    string uri() const pure => m_uri;
    string definition() const pure => m_definition;

    void setDefinition(string definition) pure
    {
        m_definition = definition;
    }

    mixin queryMixin!(
        uri, definition, setDefinition,
    );

    Json toJson() const
    {
        Json json = Json.emptyObject;
        json["uri"] = uri;
        json["definition"] = definition;
        return json;
    }

    static Dashboard fromJson(Json json)
    {
        auto instance = new typeof(this)(
            json["uri"].get!string,
            json["definition"].get!string,
        );
        return instance;
    }
}

final class DashboardManager : GraphNode
{
    private Dashboard[string] m_dashboards;

    this()
    {
    }

    string[] listDashboards() const
    {
        return m_dashboards.keys;
    }

    Dashboard createDashboard(string uri, string definition)
    {
        enforce(uri !in m_dashboards);
        Dashboard dashboard = new Dashboard(uri, definition);
        m_dashboards[uri] = dashboard;
        return dashboard;
    }

    Dashboard createScriptFromJson(Json json)
    {
        enforce(json["uri"].get!string !in m_dashboards);
        Dashboard dashboard = Dashboard.fromJson(json);
        m_dashboards[dashboard.uri] = dashboard;
        return dashboard;
    }

    Dashboard getDashboard(string uri)
    {
        enforce(uri in m_dashboards);
        return m_dashboards[uri];
    }

    void removeDashboard(string uri)
    {
        enforce(uri in m_dashboards);
        m_dashboards.remove(uri);
    }

    mixin queryMixin!(
        listDashboards, getDashboard, createDashboard, removeDashboard,
    );
}
