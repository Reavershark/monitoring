import json
import os
from pathlib import Path
from rdflib import Graph, Literal, Namespace, URIRef
from rdflib.namespace import RDF, RDFS, SOSA, SSN, XSD
from rdflib.extras.infixowl import Class

base_uri = "http://localhost:3001/ontologies"

DASHB = Namespace(f"{base_uri}/dashboard/")
IMAGE = Namespace(f"{base_uri}/image/")

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

def subj(pred=None, obj=None, filt=lambda x: True):
    return single_result(filt(graph.objects(predicate=pred, object=obj)))

def subjs(pred=None, obj=None, filt=lambda x: True):
    return list(filt(graph.objects(predicate=pred, object=obj)))

def obj(subj=None, pred=None, filt=lambda x: True):
    return single_result(filt(graph.objects(subject=subj, predicate=pred)))

def objs(subj = None, pred=None, filt=lambda x: True):
    return list(filt(graph.objects(subject=subj, predicate=pred)))

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

def get_dashb_template_instance_info(templ_inst_uri: URIRef):
    templ_uri = obj(subj=templ_inst_uri, pred=DASHB.instanceOf)
    templ_name = obj(subj=templ_uri, pred=DASHB.dashboardTemplateName)
    templ_contains_uris = objs(subj=templ_uri, pred=DASHB.dashboardTemplateContains)
    templ_inst_contains_uris = objs(subj=templ_inst_uri, pred=DASHB.dashboardTemplateInstanceContains)

    def get_arg_value_dict():
        result = dict()
        value_uris = subjs(predicate=RDF.type, object=DASHB.DashboardTemplateArgumentValue, filt=lambda x: x in templ_inst_contains_uris)
        for value_uri in value_uris:
            arg_uri = obj(subj=value_uri, pred=DASHB.setsArgument)
            key = obj(subj=arg_uri, pred=DASHB.key)
            value = obj(subj=value_uri, pred=DASHB.value)
            result[key] = value

    result = {
        "args": get_arg_value_dict(),
        "dashboard": {
            "name": templ_name,
            "uri": templ_inst_uri,
            "templateUri": templ_uri,
            "elements": [
                {
                    "uri": element_uri,
                    "definition": obj(subj=element_uri, pred=DASHB.dashboardElementDefinition),
                    "dataSourceUri": obj(subj=element_uri, pred=DASHB.dataSource)
                }
                for element_uri in
                subjs(pred=RDF.type, obj=DASHB.DashboardElement, filt=lambda x: x in templ_contains_uris)
            ]
        },
        "scripts": [
            {
                "uri": script_uri,
                "type": single_result(graph.objects(subject=script_uri, predicate=DASHB.scriptType)),
                "source": single_result(graph.objects(subject=script_uri, predicate=DASHB.scriptSourceCode))
            }
            for script_uri in
            subjs(pred=RDF.type, obj=DASHB.Script, filt=lambda x: x in templ_contains_uris)
        ]
    }

    return json.dumps(result)


def get_all_template_instance_info():
    try:
        init_graph()
        return [
            get_dashb_template_instance_info(instance)
            for instance in
            subjs(pred=RDF.type, obj=DASHB.DashboardTemplateInstance)
        ]
    except Exception as e:
        print("get_all_template_instance_info failed:", e)
