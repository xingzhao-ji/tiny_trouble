extends SceneTree
## Actual scene/player-state regression, not an audio audition. Runtime cues and
## voyage tweens execute normally; only starting puzzle/profile state is seeded.
## No engine run is authorized during an isolated hardware profiling window.

class CueProbe:
	extends "res://scripts/chapter/milk_harbor.gd"
	var cue_requests: Array[String] = []

	func sfx(sound: String) -> void:
		if sounds.has(sound): cue_requests.append(sound)
		super.sfx(sound)

const Rules = preload("res://scripts/chapter/harbor_state.gd")
const Progress = preload("res://scripts/chapter/chapter_progress.gd")
var game: Node3D
var players: Array[AudioStreamPlayer] = []
var checks := 0
var failures := 0
var profile_path: String
var settings_path: String
var demo_path: String
var input_snapshot: Dictionary = {}
var original_buses: AudioBusLayout


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	original_buses = AudioServer.generate_bus_layout()
	for action in InputMap.get_actions():
		input_snapshot[action] = {"deadzone": InputMap.action_get_deadzone(action), "events": InputMap.action_get_events(action)}
	var suffix := "%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	profile_path = "user://audio_feedback_chapter_" + suffix + ".json"
	settings_path = "user://audio_feedback_settings_" + suffix + ".cfg"
	demo_path = "user://audio_feedback_demo_" + suffix + ".json"
	var settings := ConfigFile.new()
	settings.set_value("sound", "music", 0.0)
	settings.set_value("sound", "effects", 0.0)
	settings.set_value("comfort", "reduced_motion", false)
	_check(settings.save(settings_path) == OK, "Disposable settings mute output while preserving real player playback state")
	var profile = Progress.new()
	profile.save_path = profile_path
	_check(profile.complete_stage("W01S01") and profile.complete_stage("W01S02"), "Only Harbor's two prerequisite completions are seeded")
	game = CueProbe.new()
	game.save_path = demo_path
	game.settings_path = settings_path
	game.chapter_profile_path = profile_path
	game.child_entered_tree.connect(_record_child)
	root.add_child(game)
	current_scene = game
	_check(game.save_path == demo_path and game.settings_path == settings_path and game.chapter_profile.save_path == profile_path, "All scene storage paths were assigned before readiness")
	_check(_effect_nodes().size() == 8 and _audio_nodes().size() == 9, "Real scene creates eight effect players and one independent music player")
	_check(game.music_player.playing and game.music_player.bus == "Music", "Music is playing on its own bus even when test output is muted")
	await _test_retrigger_and_priority()
	await _test_voyage_arrivals()
	await game.stop_audio()
	for player: AudioStreamPlayer in _audio_nodes():
		_check(not player.playing and player.stream == null, "stop_audio stops and releases every pooled effect and music stream")
	game.queue_free()
	await process_frame
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.erase_action(action)
	for action in input_snapshot:
		InputMap.add_action(action, input_snapshot[action].deadzone)
		for event: InputEvent in input_snapshot[action].events: InputMap.action_add_event(action, event)
	AudioServer.set_bus_layout(original_buses)
	_cleanup()
	_check(not FileAccess.file_exists(profile_path) and not FileAccess.file_exists(settings_path) and not FileAccess.file_exists(demo_path), "Disposable audio-test files were removed")
	print("%s: %d audio feedback checks; actual Harbor arrivals, cue request counts, live stream playback, bounded voices/retriggering, priority, isolated buses, and clean shutdown. No subjective audition." % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)


func _test_retrigger_and_priority() -> void:
	var original_ids: Array[int] = _player_ids()
	for _attempt: int in range(40): game.reject("Repeated invalid-input fixture")
	_check(_effect_nodes().size() == 8 and _player_ids() == original_ids, "Repeated refused inputs cannot allocate additional effect players")
	_check(_playing("reject").size() == 1, "A same-frame burst of forty refusals starts one actual refusal voice")
	await create_timer(0.05).timeout
	var refusal: AudioStreamPlayer = _playing("reject")[0] if not _playing("reject").is_empty() else null
	_check(refusal != null and refusal.has_stream_playback(), "The refusal has an actual instantiated playback before the retrigger-guard check")
	if refusal != null:
		# The headless driver may report a zero cursor while output is muted.
		# Godot creates a new AudioStreamPlayback on play(), so instance identity
		# directly detects an unwanted restart without relying on audio-device time.
		var playback: AudioStreamPlayback = refusal.get_stream_playback()
		game.reject("Refused again during the same short cue guard")
		_check(refusal.playing and refusal.get_stream_playback() == playback, "A refusal inside the guard neither stacks nor replaces the existing playback")
	game.sfx("resize_up")
	_check(_playing("resize_up").size() == 1, "An accepted resize cue starts immediately beside the refusal")
	await create_timer(0.12).timeout
	game.reject("A later refusal may retrigger")
	_check(_playing("reject").size() == 1 and _effect_nodes().size() == 8, "A later same-cue retrigger replaces its tail rather than stacking another voice")
	# Rebuilding audio on an unsuccessful scene transition must reuse the pool.
	game.build_audio()
	game.build_audio()
	_check(_player_ids() == original_ids and _audio_nodes().size() == 9, "Repeated audio setup reuses the same bounded players")
	_check(is_inf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) and is_inf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects"))), "Audio setup preserves the isolated zero-volume bus settings")
	for cue: String in ["resize_up", "resize_down", "pickup", "place", "reject", "jump", "land", "launch"]:
		game.sfx(cue)
	_check(_playing_effects() == 8, "Priority fixture occupies every actual effect voice with ordinary cues")
	game.sfx("checkpoint")
	_check(_playing("checkpoint").size() == 1 and _playing_effects() == 8, "An earned checkpoint immediately replaces a lower-priority voice under load")
	game.sfx("discovery")
	game.sfx("complete")
	_check(_playing("checkpoint").size() == 1 and _playing("discovery").size() == 1 and _playing("complete").size() == 1, "Checkpoint, discovery and completion all retain active playback voices under ordinary load")
	for _attempt: int in range(40):
		game.sfx("reject")
		game.sfx("jump")
		game.sfx("land")
	_check(_playing("complete").size() == 1 and _playing("checkpoint").size() == 1 and _playing("discovery").size() == 1, "Repeated low-priority requests do not displace important cues")
	_check(_player_ids() == original_ids and _playing_effects() <= 8, "Stress requests keep both allocated players and active effect voices bounded")
	await game.stop_audio()
	_check(_playing_effects() == 0, "A loaded pool stops cleanly before the voyage scenarios")
	for _retry: int in range(3):
		game.build_audio()
		_check(_player_ids() == original_ids and _audio_nodes().size() == 9 and game.music_player.playing, "Failed-navigation stop/rebuild reuses all eight effects and the original music node")
		game.sfx("pickup")
		_check(_playing("pickup").size() == 1, "A rebuilt pool immediately plays accepted cues again")
		await game.stop_audio()
		_check(_playing_effects() == 0 and game.music_player.stream == null, "Each failed-navigation retry releases all streams before another rebuild")
	game.build_audio()


func _test_voyage_arrivals() -> void:
	game.on_command("start", null)
	var rules = Rules.new()
	rules.resize("cereal", 2)
	rules.board()
	game.state = rules
	game.sync_props(false)
	game.respawn()
	_check(game.state.aboard and game.state.phase == "near" and game.state.checkpoint == 1, "Actual voyage fixture begins at the earned near mooring aboard a large raft")
	var ids: Array[int] = _player_ids()
	for destination: String in ["shoal", "far"]:
		if destination == "far":
			game.target = "cargo"
			game.resize_target(0)
			await _wait_idle(2.0)
			_check(int(game.state.sizes.cargo) == 0 and not game.busy(), "Production resize prepares a small parcel for the second voyage")
		game.cue_requests.clear()
		game.interact()
		_check(game.state.phase == ("to_shoal" if destination == "shoal" else "to_far") and game.voyage_tween.is_running(), "Production interaction starts the real " + destination + " voyage tween")
		var deadline: int = Time.get_ticks_usec() + 4000000
		while game.state.phase != destination and Time.get_ticks_usec() < deadline:
			await process_frame
		_check(game.state.phase == destination and game.state.checkpoint == (2 if destination == "shoal" else 3), "Real voyage arrival earns the expected safe mooring")
		_check(game.cue_requests.count("checkpoint") == 1, "The " + destination + " arrival requests exactly one checkpoint cue before any anti-stacking filter")
		var actual: Array[AudioStreamPlayer] = _playing("checkpoint")
		_check(actual.size() == 1, "Exactly one observed child player actually plays the checkpoint stream at " + destination)
		if not actual.is_empty():
			_check(actual[0].stream == game.sounds.checkpoint and actual[0].bus == "Effects" and actual[0].playing, "The arrival uses the real checkpoint asset and effects bus")
		_check(_player_ids() == ids, "A voyage arrival reuses the existing audio players")
		await _wait_idle(2.0)
		_check(game.cue_requests.count("checkpoint") == 1, "No delayed dock/arrival callback duplicates the earned cue")
		# Audio completion is delivered by the mixer, independently of scene
		# timers. The 1.38s asset previously had only70ms of scheduling margin.
		var audio_deadline := Time.get_ticks_usec() + int((game.sounds.checkpoint.get_length() + 0.75) * 1000000)
		while not _playing("checkpoint").is_empty() and Time.get_ticks_usec() < audio_deadline:
			await process_frame
		_check(_playing("checkpoint").is_empty(), "The checkpoint voice finishes naturally before the next scenario")


func _record_child(child: Node) -> void:
	if child is AudioStreamPlayer: players.append(child)


func _audio_nodes() -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in players:
		if is_instance_valid(player) and player.is_inside_tree(): result.append(player)
	return result


func _effect_nodes() -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _audio_nodes():
		if player.bus == "Effects": result.append(player)
	return result


func _playing(cue: String) -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in _effect_nodes():
		if player.playing and player.stream == game.sounds[cue]: result.append(player)
	return result


func _playing_effects() -> int:
	var result := 0
	for player: AudioStreamPlayer in _effect_nodes():
		if player.playing: result += 1
	return result


func _player_ids() -> Array[int]:
	var result: Array[int] = []
	for player: AudioStreamPlayer in _audio_nodes(): result.append(player.get_instance_id())
	result.sort()
	return result


func _wait_idle(seconds: float) -> void:
	var deadline: int = Time.get_ticks_usec() + int(seconds * 1000000)
	while game.busy() and Time.get_ticks_usec() < deadline: await process_frame
	_check(not game.busy(), "Authored scene transitions settle within the bounded wait")


func _cleanup() -> void:
	for path: String in [profile_path, settings_path, demo_path]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
