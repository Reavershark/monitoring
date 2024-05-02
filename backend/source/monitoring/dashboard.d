module monitoring.dashboard;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.graph_root : GraphRoot;
import monitoring.resource_graph.mixins : queryMixin;
import monitoring.script : Script;

import std.algorithm : map;
import std.array : array;
import std.exception : enforce;

import vibe.data.json : Json;

@safe:

final class Dashboard : GraphNode
{
    private string m_uri;
    private DashboardElement[] m_elements;

    this(string uri, DashboardElement[] elements = [])
    {
        m_uri = uri;
        m_elements = elements;
    }

    string uri() const pure => m_uri;
    DashboardElement[] elements() pure => m_elements;

    mixin queryMixin!(
        uri, elements,
    );

    Json toJson() const
    {
        Json json = Json.emptyObject;
        json["uri"] = uri;
        json["elements"] = m_elements.map!(el => el.toJson).array;
        return json;
    }

    static Dashboard fromJson(Json json)
    {
        auto instance = new typeof(this)(
            json["uri"].get!string,
            json["elements"].get!(Json[]).map!(j => DashboardElement.fromJson(j)).array,
        );
        return instance;
    }
}

final class DashboardElement : GraphNode
{
    private string m_uri;
    private string m_definition;
    private Script m_dataSource;

    this(string uri, string definition, Script dataSource)
    {
        m_uri = uri;
        m_definition = definition;
        m_dataSource = dataSource;
    }

    string uri() const pure => m_uri;
    string definition() const pure => m_definition;
    string dataSourceUri() const pure => m_dataSource.uri;
    Script dataSource() pure => m_dataSource;

    Json toJson() const
    {
        Json json = Json.emptyObject;
        json["uri"] = uri;
        json["definition"] = definition;
        json["dataSourceUri"] = dataSourceUri;
        return json;
    }

    static DashboardElement fromJson(Json json)
    {
        auto instance = new typeof(this)(
            json["uri"].get!string,
            json["definition"].get!string,
            GraphRoot.getInstance.scriptManager.getScript(json["dataSourceUri"].get!string),
        );
        return instance;
    }

    mixin queryMixin!(uri, definition, dataSourceUri, dataSource);
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

    Dashboard createDashboardFromJson(Json json)
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
        listDashboards, getDashboard,
    );
}
