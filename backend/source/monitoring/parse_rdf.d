module monitoring.parse_rdf;

import monitoring.dashboard : Dashboard;
import monitoring.resource_graph.graph : GraphNode;
import monitoring.resource_graph.graph_root : GraphRoot;
import monitoring.resource_graph.mixins;
import monitoring.script : Script;

import std.algorithm : map;
import std.array : replace;
import std.format : f = format;

import vibe.core.log;
import vibe.data.json : Json, parseJsonString;

import pyd.pyd, pyd.embedded;

@safe:

enum string pyModule = "parse_rdf";
enum string pyCode = import("source_python/parse_rdf.py");

shared static this() @trusted
{
    on_py_init(() => add_module!(ModuleName!pyModule), PyInitOrdering.Before);
    on_py_init(() => py_stmts(pyCode, pyModule), PyInitOrdering.After);
}

string[] getAllTemplateInstanceInfo() @trusted
{
    return py_eval!(string[])("get_all_template_instance_info()", pyModule);
}

void rdfDiscoverAll()
{
    GraphRoot gr = GraphRoot.getInstance;
    foreach (Json json; getAllTemplateInstanceInfo.map!parseJsonString)
    {
        logInfo(f!"Processing Dashboard %s"(json["dashboard"]["name"].get!string));
        logInfo(f!"JSON: %s"(json));

        string replaceTemplateVars(in string s)
        {
            string result = s.dup;
            foreach (string key, Json jsonValue; json["args"].get!(Json[string]))
            {
                string value = jsonValue.get!string;
                result = result.replace(f!"{{%s}}"(key), value);
            }
            return result;
        }

        json["scripts"] = replaceTemplateVars(json["scripts"].toString).parseJsonString;
        json["dashboard"] = replaceTemplateVars(json["dashboard"].toString).parseJsonString;

        foreach (Json scriptJson; json["scripts"].get!(Json[]))
            gr.scriptManager.createScriptFromJson(scriptJson);

        gr.dashboardManager.createDashboardFromJson(json["dashboard"]);
    }
}
