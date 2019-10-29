const PodTemplate = preload("res://Scripts/Entities/PodTemplate.gd")

var http
var api_server_host : String
var api_server_port : int

var client_poll_interval_ms = 500
var timeout_seconds = 10

var auth_token = ""
var dev_token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJjbXNlcnZpY2UiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlY3JldC5uYW1lIjoiZGVmYXVsdC10b2tlbi1obTVjbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQudWlkIjoiOTUyZjE4MGYtYjhkMC00NWJlLWIzZWYtZjFiNWRmMDIzYTE1Iiwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmNtc2VydmljZTpkZWZhdWx0In0.YCFdIzd9_MFoKY9kOwixK3NzEOaOKo7oh6_qMl0owIQ5SG0_6hqVgvMRY5vh1futlQcYAX7TC0E8CCnqWvxTGsXvf6eTZ5S2pbVXiY7jjkR75lz6O18F_ajRQmMdH8IFBGTmEwdX0vi01MAkFTuDX1aTiRhEdyV4AtOQMw90LFSeNBRE6Jb3UUnSVNCahOqZTDtYSEQGiNbCV-a9RT_7rufxozc1SeYrpya1iIiaSDK-v_AVeWKGudV46kZsKVTcij-nFMU1i93l8ePOSKJy1R2viAXEuXgFbxGKALMMs-oghrManOob5m3cqzmaOfyxlB78hoTx3JIDL7HdXmDNDw"


func _init(api_host, api_port):
    http = HTTPClient.new()
    self.api_server_host = api_host
    self.api_server_port = api_port


func get_pod_list():
    var pods_response = read_pods_from_api()
    var pod_templates = pods_from_json(pods_response)
    return pod_templates

func pods_from_json(json_data):
    var pod_items = json_data["items"]
    var pod_template_list = []
    for p in pod_items:
        var pod_template = PodTemplate.new(p["metadata"]["name"])
        pod_template_list.append(pod_template)
    return pod_template_list

func read_pods_from_api() -> String:
    var err = http.connect_to_host(api_server_host, api_server_port, true, false)
    assert(err == OK) # TODO: Make more graceful check
    var time_waited = 0
    while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
        http.poll()
        print("Connecting to %s:%s ..." % [str(api_server_host), str(api_server_port)])
        OS.delay_msec(client_poll_interval_ms)
        time_waited += client_poll_interval_ms
        if time_waited/1000 >= timeout_seconds:
            print("ERROR: Timed out waiting for connection")
            return ""
    assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
    var headers = [
        "Authorization: Bearer " + dev_token 
    ]
    err = http.request(HTTPClient.METHOD_GET, "/api/v1/pods", headers)
    assert(err == OK)
    
    time_waited = 0
    while http.get_status() == HTTPClient.STATUS_REQUESTING:
        http.poll()
        OS.delay_msec(client_poll_interval_ms)
        time_waited += client_poll_interval_ms
        if time_waited/1000 >= timeout_seconds:
            print("ERROR: Timed out waiting for response")
            return ""
    assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED)
    var read_body = PoolByteArray()
    print("code: ", http.get_response_code())
    if http.has_response():
        while http.get_status() == HTTPClient.STATUS_BODY:
            http.poll()
            var chunk = http.read_response_body_chunk()
            if chunk.size() == 0:
                OS.delay_usec(1000) # Wait for buffers to fill if empty
            else:
                read_body = read_body + chunk
    var body_text = read_body.get_string_from_ascii()
    var body_json = JSON.parse(body_text).result
    return body_json 
    