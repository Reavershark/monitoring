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
    gr.dashboardManager.removeAllDashboards;
    gr.scriptManager.removeAllScripts;

    foreach (Json json; getAllTemplateInstanceInfo.map!parseJsonString)
    {
        logInfo(f!"Processing Dashboard %s"(json["dashboard"]["name"].get!string));
        logInfo(f!"JSON: %s"(json));

        string replaceTemplateVars(in string s)
        {
            if (json["args"].type is Json.Type.null_)
                return s;

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

void rdfDiscoverAndWatchForChanges() nothrow
{
    import core.time : seconds;
    import fswatch;
    import vibe.core.core : InterruptException, sleep, yield;

    void loop() @trusted
    {
        logInfo("Initial rdfDiscoverAll");
        rdfDiscoverAll;

        FileWatch watcher = FileWatch("static/ontologies/", /*recursive:*/ true);

        while (true)
        {
            if (watcher.getEvents.length)
            {
                logInfo("Detected change in ontologies dir, re-running rdfDiscoverAll");
                rdfDiscoverAll;
            }
            yield;
        }
    }

    try
    {
        while (true)
        {
            try
                loop();
            catch (Exception e)
            {
                logWarn("rdfDiscoverAndWatchForChanges loop failed: " ~ e.msg);
                logWarn((() @trusted => e.info.toString)());
            }

            sleep(2.seconds);
        }
    }
    catch (Exception e)
    {
        logError("rdfDiscoverAndWatchForChanges task failed: " ~ e.msg);
    }
}
