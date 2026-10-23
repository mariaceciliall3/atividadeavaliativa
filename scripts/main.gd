
extends Node2D

const PORT := 7000
const MAX_CLIENTS := 1

const PLAYER_1_SCENE: PackedScene = preload("res://personagem/player_1.tscn")
const PLAYER_2_SCENE: PackedScene = preload("res://personagem/player_2.tscn")

const VITORIA_PLAYER_1: PackedScene = preload("res://cenas/vitoria/vitoria_player_1.tscn")
const VITORIA_PLAYER_2: PackedScene = preload("res://cenas/vitoria/vitoria_player_2.tscn")

@onready var players: Node2D = $Players
@onready var status_label: Label = $CanvasLayer/Interface/StatusLabel
@onready var spawner: MultiplayerSpawner = $MultiplayerSpawner

var match_finished := false


func _ready() -> void:
	# Configura a função que cria cada personagem em todas as instâncias.
	spawner.spawn_function = _criar_jogador_replicado

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	$CanvasLayer/Interface/HostButton.pressed.connect(_on_host_button_pressed)
	$CanvasLayer/Interface/JoinButton.pressed.connect(_on_join_button_pressed)

	$Level/portal.jogador_entrou.connect(_on_portal_jogador_entrou)


func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)

	if error != OK:
		status_label.text = "Não foi possível criar o servidor"
		print("Erro ao criar servidor: ", error)
		return

	multiplayer.multiplayer_peer = peer

	status_label.text = "Servidor criado. Aguardando jogador"
	print("Servidor iniciado. ID local: ", multiplayer.get_unique_id())

	spawn_player(1)


func join_game(address: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address, PORT)

	if error != OK:
		status_label.text = "Não foi possível iniciar a conexão"
		print("Erro ao iniciar conexão: ", error)
		return

	multiplayer.multiplayer_peer = peer
	status_label.text = "Conectando..."


func _on_host_button_pressed() -> void:
	print("Botão Servidor pressionado")
	host_game()


func _on_join_button_pressed() -> void:
	var address: String = $CanvasLayer/Interface/AddressLineEdit.text.strip_edges()

	if address.is_empty():
		address = "127.0.0.1"

	join_game(address)


func _on_connected_to_server() -> void:
	status_label.text = "Conectado ao servidor"
	print("Cliente conectado. ID local: ", multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	status_label.text = "Falha na conexão"
	print("Falha na conexão com o servidor")


func _on_server_disconnected() -> void:
	status_label.text = "Conexão com o servidor encerrada"
	print("Servidor desconectado")


func _on_peer_connected(id: int) -> void:
	print("Peer conectado. ID recebido: ", id)

	if multiplayer.is_server():
		spawn_player(id)
		status_label.text = "Jogador conectado!"


func _on_peer_disconnected(id: int) -> void:
	var jogador := players.get_node_or_null(str(id))

	if jogador != null and multiplayer.is_server():
		# Remover o filho do Spawn Path no servidor faz o MultiplayerSpawner
		# anunciar o despawn aos clientes automaticamente.
		jogador.queue_free()
		status_label.text = "Jogador desconectado"
		print("Jogador desconectado: ", id)


func spawn_player(id: int) -> void:
	if not multiplayer.is_server():
		return

	if id <= 0:
		print("ID inválido: ", id)
		return

	if players.has_node(str(id)):
		print("Jogador já existe: ", id)
		return

	var posicao_inicial: Vector2

	if id == 1:
		posicao_inicial = $SpawnHost.global_position
	else:
		posicao_inicial = $SpawnClient.global_position

	print("Solicitando criação do jogador ", id, " em ", posicao_inicial)

	spawner.spawn({
		"id": id,
		"position": posicao_inicial
	})


func _criar_jogador_replicado(dados: Dictionary) -> Node:
	var id: int = dados["id"]
	var posicao_inicial: Vector2 = dados["position"]

	var cena_jogador: PackedScene

	if id == 1:
		cena_jogador = PLAYER_1_SCENE
	else:
		cena_jogador = PLAYER_2_SCENE

	var jogador := cena_jogador.instantiate()
	jogador.name = str(id)

	# Define a posição antes de o MultiplayerSpawner adicionar o nó.
	jogador.position = posicao_inicial

	print(
		"Instanciando jogador ", id,
		" | Posição inicial: ", jogador.position
	)

	return jogador



func _on_portal_jogador_entrou(body: Node2D) -> void:
	if not multiplayer.is_server():
		return

	if match_finished:
		return

	if not body.is_in_group("players"):
		return

	if not body.name.is_valid_int():
		return

	match_finished = true

	var vencedor_id: int = body.name.to_int()
	print("Vencedor decidido pelo servidor: ", vencedor_id)
	_finalizar_com_vitoria.call_deferred(vencedor_id)


func _finalizar_com_vitoria(vencedor_id: int) -> void:
	# O RPC mantém o mesmo vencedor em todas as instâncias. A tela de vitória
	# será sobreposta à fase sem remover o MultiplayerSpawner nem os jogadores.
	anunciar_vencedor.rpc(vencedor_id)



@rpc("authority", "call_local", "reliable")
func anunciar_vencedor(vencedor_id: int) -> void:
	if get_node_or_null("VictoryOverlay") != null:
		return

	match_finished = true

	var jogador_vencedor := players.get_node_or_null(str(vencedor_id)) as CharacterBody2D
	if jogador_vencedor == null:
		push_error("O servidor anunciou um vencedor sem jogador replicado: " + str(vencedor_id))
		return

	for jogador in players.get_children():
		jogador.set_physics_process(false)
		jogador.set_process(false)
		if jogador != jogador_vencedor:
			jogador.visible = false
			jogador.set_collision_layer(0)
			jogador.set_collision_mask(0)
		else:
			jogador.velocity = Vector2.ZERO
			jogador.position = Vector2(get_viewport_rect().size.x * 0.5, 203.0)
			jogador.set("spawn_position", jogador.position)
			jogador.visible = true
			jogador.set_physics_process(true)
			jogador.set_process(true)
	players.visible = true
	players.z_index = 10
	# Retira a fase antiga do espaço de colisão sem removê-la da árvore. Isso
	# também deixa possível restaurá-la para uma revanche posteriormente.
	$Level.position = Vector2(100000.0, 100000.0)
	$Level.visible = false
	$CanvasLayer.visible = false

	var cena_vitoria: PackedScene

	if vencedor_id == 1:
		cena_vitoria = VITORIA_PLAYER_1
	else:
		cena_vitoria = VITORIA_PLAYER_2

	var tela_vitoria := cena_vitoria.instantiate() as Control
	tela_vitoria.name = "VictoryOverlay"
	add_child(tela_vitoria)
	_ajustar_tela_vitoria(tela_vitoria)
	get_viewport().size_changed.connect(_ajustar_tela_vitoria.bind(tela_vitoria))


func _ajustar_tela_vitoria(tela_vitoria: Control) -> void:
	if not is_instance_valid(tela_vitoria):
		return
	tela_vitoria.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tela_vitoria.position = Vector2.ZERO
	tela_vitoria.size = get_viewport_rect().size
	if match_finished:
		for jogador in players.get_children():
			if jogador.visible:
				jogador.position.x = get_viewport_rect().size.x * 0.5
