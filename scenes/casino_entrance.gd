extends Area2D

func _on_body_entered(body):
	if body.has_method("decide_enter_casino"):
		print("Ktoś wszedł w entrance:", body)
		body.decide_enter_casino()
