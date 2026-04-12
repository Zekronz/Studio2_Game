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

func time_to_judgement(time : float):
	if time <= SEC[PERFECT]:
		return PERFECT
	elif time <= SEC[GREAT]:
		return GREAT
	elif time <= SEC[GOOD]:
		return GOOD
	elif time <= SEC[OK]:
		return OK
	elif time <= SEC[BAD]:
		return BAD
	return MISS
