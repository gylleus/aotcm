extends Control

var connection_ok = false
var namespace_ok = false

func _process(delta):
    $ServerSyncInterval/SecondsDisplay.text = str($ServerSyncInterval/HSlider.value) + "S"
    $Namespace/LineEdit.editable = !$Namespace/CheckBox.pressed
    namespace_ok = $Namespace/CheckBox.pressed or $Namespace/LineEdit.text != ""
    $OKButton.disabled = !(namespace_ok and connection_ok)
    $"../Connected".visible = KubernetesServer.connected
    KubernetesServer.client_poll_interval = $ServerSyncInterval/HSlider.value

func port_updated():
    var pods = $KubernetesStateHandler.update_state()
    $PortLabel/LoadingImage.visible = true
    $PortLabel/ConnectionOK.visible = false
    $PortLabel/ConnectionNotOk.visible = false

func port_changed(new_text):
    KubernetesServer.proxy_port = int($PortLabel/LineEdit.text)
    connection_ok = false
    update_connection_state()

func _on_KubernetesStateHandler_state_updated():
    connection_ok = true    
    update_connection_state()
    
func _on_KubernetesStateHandler_update_failed():
    connection_ok = false
    update_connection_state()

func update_connection_state():
    $PortLabel/LoadingImage.visible = false
    $PortLabel/ConnectionOK.visible = connection_ok
    $PortLabel/ConnectionNotOk.visible = !connection_ok

func _on_BackButton_pressed():
    visible = false

func _on_OKButton_pressed():
    KubernetesServer.proxy_port = int($PortLabel/LineEdit.text)
    KubernetesServer.namespace = $Namespace/LineEdit.text
    KubernetesServer.connected = true
    visible = false

func _on_KubernetesConnect_pressed():
    visible = true


func _on_StartGame_pressed():
    pass # Replace with function body.
