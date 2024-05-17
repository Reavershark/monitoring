module monitoring.dashboard;

import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.graph_root : GraphRoot;
import monitoring.resource_graph.mixins : graphNodeMixin;
import monitoring.script : Script;
import monitoring.util.meta : Pack;

import std.algorithm : canFind, map, remove, countUntil;
import std.array : array;
import std.exception : enforce;
import std.meta : AliasSeq;

import vibe.data.json : Json, serializeToJson;

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
            json["elements"].get!(Json[])
                .map!(j => DashboardElement.fromJson(j))
                .array,
        );
        return instance;
    }

    mixin graphNodeMixin!(
        Pack!(uri, elements),
    );
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

    mixin graphNodeMixin!(
        Pack!(uri, definition, dataSourceUri, dataSource),
    );
}

final class DashboardManager : GraphNode
{
    private Dashboard[string] m_dashboards;

    string[] listDashboards() const pure => m_dashboards.keys;

    void removeAllDashboards()
    {
        scope (success)
            raiseDashboardsChanged;

        m_dashboards = null;
    }

    Dashboard createDashboardFromJson(Json json)
    {
        scope (success)
            raiseDashboardsChanged;

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
        scope (success)
            raiseDashboardsChanged;

        enforce(uri in m_dashboards);
        m_dashboards.remove(uri);
    }

    void raiseDashboardsChanged()
    {
        immutable Json eventData = listDashboards.serializeToJson;
        raise!"dashboardsChanged"(eventData);
    }

    mixin graphNodeMixin!(
        Pack!(listDashboards, getDashboard),
        ["dashboardsChanged"],
    );
}
