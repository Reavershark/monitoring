import json
import os
from pathlib import Path
from rdflib import Graph, Literal, Namespace, URIRef
from rdflib.namespace import RDF, RDFS, SOSA, SSN, XSD
from rdflib.extras.infixowl import Class

base_uri = "http://localhost:3001/ontologies"

CORE = Namespace(f"{base_uri}/core/")

graph = Graph()

def init_graph():
    global graph
    graph = Graph()
    for file in Path(os.getcwd(), "static/ontologies").rglob("*.ttl"):
        graph.parse(file)

def single_result(it):
    l = list(it)
    if len(l) == 0:
        raise Exception("Expected single result, got none")
    if len(l) >= 2:
        raise Exception("Expected single result, got multiple")
    return l[0]

def rdf_is_sub_class(this: Class, other: Class):
    if other in this.subClassOf:
        return True
    for sub_class in this.subClassOf:
        if rdf_is_sub_class(sub_class, other):
            return True
    return False

def rdf_is_instance(this_uri: URIRef, other_class_uri: URIRef, graph: Graph):
    other_class = Class(other_class_uri, graph=graph)
    for subj, pred, obj in graph:
        if pred == RDF.type and subj == this_uri:
            this_class = Class(obj, graph=graph)
            if this_class == other_class or rdf_is_sub_class(this_class, other_class):
                return True
    return False

def get_template_instance_info(dashboard_template_instance_uri: URIRef):
    dashboard_template_uri = single_result(graph.objects(subject=dashboard_template_instance_uri, predicate=CORE.instanceOf))
    dashboard_template_name = single_result(graph.objects(subject=dashboard_template_uri, predicate=CORE.dashboardTemplateName))
    dashboard_template_contains_uris = list(graph.objects(subject=dashboard_template_uri, predicate=CORE.dashboardTemplateContains))
    dashboard_template_instance_contains_uris = list(graph.objects(subject=dashboard_template_instance_uri, predicate=CORE.dashboardTemplateInstanceContains))
    arg_values = list(filter(lambda x: x in dashboard_template_instance_contains_uris, graph.subjects(predicate=RDF.type, object=CORE.DashboardTemplateArgumentValue)))

    result = dict()
    result["args"] = dict()
    for arg_value_uri in arg_values:
        arg_uri = single_result(graph.objects(subject=arg_value_uri, predicate=CORE.setsArgument))
        key = single_result(graph.objects(subject=arg_uri, predicate=CORE.key))
        value = single_result(graph.objects(subject=arg_value_uri, predicate=CORE.value))
        result["args"][key] = value
    result["dashboard"] = dict()
    result["dashboard"]["name"] = dashboard_template_name
    result["dashboard"]["uri"] = dashboard_template_instance_uri
    result["dashboard"]["templateUri"] = dashboard_template_uri
    result["dashboard"]["elements"] = list()
    for element_uri in filter(lambda x: x in dashboard_template_contains_uris, graph.subjects(predicate=RDF.type, object=CORE.DashboardElement)):
        result["dashboard"]["elements"].append({
            "uri": element_uri,
            "definition": single_result(graph.objects(subject=element_uri, predicate=CORE.dashboardElementDefinition)),
            "dataSourceUri": single_result(graph.objects(subject=element_uri, predicate=CORE.dataSource))
        })
    result["scripts"] = list()
    for script_uri in filter(lambda x: x in dashboard_template_contains_uris, graph.subjects(predicate=RDF.type, object=CORE.Script)):
        result["scripts"].append({
            "uri": script_uri,
            "type": single_result(graph.objects(subject=script_uri, predicate=CORE.scriptType)),
            "source": single_result(graph.objects(subject=script_uri, predicate=CORE.scriptSourceCode))
        })

    return json.dumps(result)


def get_all_template_instance_info():
    try:
        init_graph()
        return [
            get_template_instance_info(instance)
            for instance
            in graph.subjects(predicate=RDF.type, object=CORE.DashboardTemplateInstance)
        ]
    except Exception as e:
        print("get_all_template_instance_info failed:", e)