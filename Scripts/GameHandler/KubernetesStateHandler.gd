extends Node

signal state_updated
signal update_failed

const PodTemplate = preload("res://Scripts/Entities/PodTemplate.gd")

var http
var pod_templates = []

func _ready():
    http = HTTPClient.new()
    get_pod_list()

func update_state():
    read_pods_from_api(KubernetesServer.namespace)

func get_pod_list():
    return pod_templates

func pods_from_json(json_data):
    var pod_items = json_data["items"]
    var pod_template_list = []
    for p in pod_items:
        var pod_template = PodTemplate.new(p["metadata"]["name"])
        pod_template_list.append(pod_template)
    return pod_template_list

func read_pods_from_api(namespace="all"):
    var URL = "/api/v1/pods"
    if namespace != "":
        URL = "/api/v1/namespaces/%s/pods" % [namespace]
    return $HTTPRequest.request("http://127.0.0.1:"+String(KubernetesServer.proxy_port)+URL,PoolStringArray([]), false)

func _on_pod_request_completed(result, response_code, headers, body):
    if response_code == 200:
        var body_text = body.get_string_from_ascii()
        var body_json = JSON.parse(body_text).result
        pod_templates = pods_from_json(body_json)
        emit_signal("state_updated")
    else:
        emit_signal("update_failed")
