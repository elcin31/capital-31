class_name GameAudio
extends Node

var voices: Array[AudioStreamPlayer]=[]

func _ready() -> void:
 for i in range(4):
  var p=AudioStreamPlayer.new();add_child(p);voices.append(p)

func play_cue(kind: String = "click") -> void:
 if not Game.settings.sound:return
 var file="res://assets/audio/"+kind+".wav"
 if not ResourceLoader.exists(file):file="res://assets/audio/click.wav"
 for p in voices:
  if not p.playing:p.stream=load(file);p.volume_db=-12;p.play();return
