extends Node

enum {
	PERFECT,
	GREAT,
	GOOD,
	OK,
	BAD,
	MISS
}

const SEC : Dictionary = {
	PERFECT: 16.5 / 1000.0,
	GREAT: 40.5 / 1000.0,
	GOOD: 73.5 / 1000.0,
	OK: 103.5 / 1000.0,
	BAD: 127.5 / 1000.0
}

const SCORE : Dictionary = {
	PERFECT: 320,
	GREAT: 300,
	GOOD: 200,
	OK: 100,
	BAD: 50,
	MISS: 0
}

func time_to_judgement(delta : float, scale : float = 1.0):
	if delta <= SEC[PERFECT] * scale:
		return PERFECT
	elif delta <= SEC[GREAT] * scale:
		return GREAT
	elif delta <= SEC[GOOD] * scale:
		return GOOD
	elif delta <= SEC[OK] * scale:
		return OK
	elif delta <= SEC[BAD] * scale:
		return BAD
	return MISS

func time_behind(delta : float, judgement, scale : float = 1.0):
	assert(judgement != MISS)
	return (delta < -(SEC[judgement] * scale))

func time_ahead(delta : float, judgement, scale : float = 1.0):
	assert(judgement != MISS)
	return (delta > (SEC[judgement] * scale))
